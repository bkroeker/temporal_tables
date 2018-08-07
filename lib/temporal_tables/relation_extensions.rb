module TemporalTables
	# Stores the time from the "at" field into each of the resulting objects
	# so that it can be carried forward in subsequent queries.
	module RelationExtensions
		def self.included(base)
			base.class_eval do
				ActiveRecord::Relation::SINGLE_VALUE_METHODS << :at
			end
		end

    def at_value
      get_value(:at) || Thread.current[:at_time]
    end

    def at_value=(value)
      set_value(:at, value)
    end

		def at(*args)
      spawn.at!(*args)
		end

		def at!(value)
			self.at_value = value
			self
		end

		def where_clause
			s = super

			at_clauses = []
			if historical?
				at_clauses << where_clause_factory.build(
					arel_table[:eff_to].gteq(at_value).and(
						arel_table[:eff_from].lteq(at_value)
					),
					[]
				)
			end

			[s, *at_clauses.compact].sum
		end

		def to_sql(*args)
			threadify_at do
				super *args
			end
		end

		def threadify_at
			if at_value && !Thread.current[:at_time]
				Thread.current[:at_time] = at_value
				result = yield
				Thread.current[:at_time] = nil
			else
				result = yield
			end
			result
		end

		def limited_ids_for(*args)
			threadify_at do
				super *args
			end
		end

		def exec_queries
			# Note that record preloading, like when you specify
			#  MyClass.includes(:associations)
			# happens within this exec_queries call.  That's why we needed to
			# store the at_time in the thread above.
			threadify_at do
				super
			end

			if historical?
				# Store the at value on each record returned
				@records.each do |r|
					r.at_value = at_value
				end
			end
			@records
		end

		def historical?
			table_name =~ /_h$/i && at_value
		end
	end

	# Uses the time from the "at" field stored in the record to filter queries
	# made to associations.
	module AssociationExtensions
		def target_scope
			# Kludge: Check +public_methods+ instead of using +responds_to?+ to
			# bypass +delegate_missing_to+ calls, as in +ActiveStorage::Attachment+.
			# Using responds_to? results in an infinite loop stack overflow.
			if @owner.public_methods.include?(:at_value)
				# If this is a history record but no at time was given,
				# assume the record's effective to date
				super.at(@owner.at_value || @owner.eff_to)
			else
				super
			end
		end
	end

	# Uses the at time when fetching preloaded records
	module PreloaderExtensions
		def build_scope
			# It seems the at time can be in either of these places, but not both,
			# depending on when the preloading happens to be done
			at_time = @owners.first.at_value if @owners.first.respond_to?(:at_value)
			at_time ||= Thread.current[:at_time]

			if at_time
				super.at(at_time)
			else
				super
			end
		end
	end

end

ActiveRecord::Relation.send :prepend, TemporalTables::RelationExtensions
ActiveRecord::Associations::Association.send :prepend, TemporalTables::AssociationExtensions
ActiveRecord::Associations::Preloader::Association.send :prepend, TemporalTables::PreloaderExtensions
