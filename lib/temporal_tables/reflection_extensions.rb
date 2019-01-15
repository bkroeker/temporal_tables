module TemporalTables
	# This is required for eager_load to work in Rails 5.2.x
	module AbstractReflectionExtensions
		def build_join_constraint(table, foreign_table)
			constraint = super
			if at_value = Thread.current[:at_time]
				constraint = constraint.and(klass.build_temporal_constraint(at_value))
			end
			constraint
		end
	end
end

case Rails::VERSION::MAJOR
when 5
	case Rails::VERSION::MINOR
	when 2
		ActiveRecord::Reflection::AbstractReflection.prepend TemporalTables::AbstractReflectionExtensions
	end
end

