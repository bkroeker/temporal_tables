module TemporalTables
	# Adds the "at" method to filter history results to records active 
	# at a certain time
	module QueryExtensions
		def self.included(base)
			base.class_eval do
				alias_method_chain :collapse_wheres, :time

				# Add the "at" method to relations in the same fashion that 
				# methods like "where" and "limit" are added
				ActiveRecord::Relation::SINGLE_VALUE_METHODS << :at

				# "at" accepts a Time, and returns records from the temporal
				# tables which were active at that time.
				define_method :at do |value|
					relation = clone
					relation.at_value = value
					relation
				end
			end
		end

		# Here we mix in the "at" behaviour:
		# For each table in the query, filter the results to records which
		# were active at that time.
		def collapse_wheres_with_time(arel, wheres)
			# Find all the tables referenced
			table_names = ([arel.source.left] + arel.source.right.map(&:left)).map(&:name)

			# For each, add clauses to fetch records from the appropriate time 
			table_names.each do |name|
				if name =~ /_h$/i && @at_value
					wheres += build_where("#{name}.eff_to >= ?", [@at_value])
					wheres += build_where("#{name}.eff_from <= ?", [@at_value])
				end
			end

			# Continue, good sir...
			collapse_wheres_without_time(arel, wheres)
		end
	end

	# Stores the time from the "at" field into each of the resulting objects
	# so that it can be carried forward in subsequent queries.
	module RelationExtensions
		def self.included(base)
			base.class_eval do
				alias_method_chain :exec_queries, :time

				attr_accessor :at_value
			end
		end

		def exec_queries_with_time
			history = table_name =~ /_h$/i && @at_value

			# Store the at_time in the thread so that the preloader has access
			if history
				Thread.current[:at_time] = @at_value
			end

			# Note that record preloading, like when you specify 
			#  MyClass.includes(:associations)
			# happens within this exec_queries call.  That's why we needed to
			# store the at_time in the thread above.
			exec_queries_without_time
			
			if history
				# Clean out the thread
				Thread.current[:at_time] = nil

				# Store the at value on each record returned
				# TODO: traverse preloaded associations too
				@records.each do |r|
					r.at_value = @at_value
				end
			end
			@records
		end
	end

	# Uses the time from the "at" field stored in the record to filter queries
	# made to associations.
	module AssociationExtensions
		def self.included(base)
			base.class_eval do
				alias_method_chain :target_scope, :at_time
			end
		end

		def target_scope_with_at_time
			if @owner.respond_to?(:at_value)
				# If this is a history record but no at time was given, 
				# assume the record's effective to date
				target_scope_without_at_time.at(@owner.at_value || @owner.eff_to)
			else
				target_scope_without_at_time
			end
		end
	end

	# Uses the at time when fetching preloaded records
	module PreloaderExtensions
		def self.included(base)
			base.class_eval do
				alias_method_chain :build_scope, :at_time
			end
		end

		def build_scope_with_at_time
			# It seems the at time can be in either of these places, but not both,
			# depending on when the preloading happens to be done
			at_time = @owners.first.at_value if @owners.first.respond_to?(:at_value)
			at_time ||= Thread.current[:at_time]

			if at_time
				build_scope_without_at_time.at(at_time)
			else
				build_scope_without_at_time
			end
		end
	end

end

ActiveRecord::QueryMethods.send :include, TemporalTables::QueryExtensions
ActiveRecord::Relation.send :include, TemporalTables::RelationExtensions
ActiveRecord::Associations::Association.send :include, TemporalTables::AssociationExtensions
ActiveRecord::Associations::Preloader::Association.send :include, TemporalTables::PreloaderExtensions
