module TemporalTables
  # This is required for eager_load to work in Rails 5.2.x
  module AbstractReflectionExtensions
    if ActiveRecord.version > ::Gem::Version.new("5.2.3")
      def join_scope(table, foreign_table, foreign_klass)
        constraint = super
        at_value = Thread.current[:at_time]

        return constraint unless at_value

        constraint.where(klass.build_temporal_constraint(at_value))
      end

    else
      def build_join_constraint(table, foreign_table)
        constraint = super
        at_value = Thread.current[:at_time]

        return constraint unless at_value

        constraint.and(klass.build_temporal_constraint(at_value))
      end
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
