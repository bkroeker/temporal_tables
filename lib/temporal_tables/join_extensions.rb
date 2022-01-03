module TemporalTables
  # This is required for eager_load to work in Rails 5.0.x
  module JoinDependencyExtensions
    def build_constraint(klass, table, key, foreign_table, foreign_key)
      constraint = super
      at_value = Thread.current[:at_time]
      return constraint unless at_value

      constraint.and(klass.build_temporal_constraint(at_value))
    end
  end
end

case Rails::VERSION::MAJOR
when 5
  case Rails::VERSION::MINOR
  when 0, 1, 2
    ActiveRecord::Associations::JoinDependency::JoinAssociation.prepend(TemporalTables::JoinDependencyExtensions)
  end
end
