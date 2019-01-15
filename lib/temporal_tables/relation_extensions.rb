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
			case Rails::VERSION::MINOR
			when 0
				@values.fetch(:at, nil) || Thread.current[:at_time]
			else
				get_value(:at) || Thread.current[:at_time]
			end
		end

		def at_value=(value)
			case Rails::VERSION::MINOR
			when 0
				@values[:at] = value
			else
				set_value(:at, value)
			end
		end

		def at(*args)
			spawn.at!(*args)
		end

		def at!(value)
			self.at_value = value
			self.where!(klass.build_temporal_constraint(value))
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

		# Only needed for Rails 5.1.x
		def default_value_for(name)
			if name == :at
				nil
			else
				super(name)
			end
		end
	end
end

ActiveRecord::Relation.prepend TemporalTables::RelationExtensions
