module TemporalTables
  # This is required for eager_load to work in Rails 5.2.x, 6.1
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

prepend_reflection = case Rails::VERSION::MAJOR
  when 5
    Rails::VERSION::MINOR >= 2
  when 6
    Rails::VERSION::MINOR >= 1
  else
    true
end
ActiveRecord::Reflection::AbstractReflection.prepend TemporalTables::AbstractReflectionExtensions if prepend_reflection
