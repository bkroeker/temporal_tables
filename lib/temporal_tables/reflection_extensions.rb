# frozen_string_literal: true

module TemporalTables
  # This is required for eager_load to work in 6.1
  module AbstractReflectionExtensions
    def join_scope(table, foreign_table, foreign_klass)
      constraint = super
      at_value = Thread.current[:at_time]

      return constraint unless at_value

      constraint.where(klass.build_temporal_constraint(at_value))
    end
  end
end

prepend_reflection = ActiveRecord.version > ::Gem::Version.new('6.1.0')
ActiveRecord::Reflection::AbstractReflection.prepend TemporalTables::AbstractReflectionExtensions if prepend_reflection
