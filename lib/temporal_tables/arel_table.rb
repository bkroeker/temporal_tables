# frozen_string_literal: true

module TemporalTables
  # This is required for eager_load to work
  module ArelTable
    def create_join(to, constraint = nil, klass = Arel::Nodes::InnerJoin)
      join = super
      at_value = Thread.current[:at_time]
      if at_value
        join =
          join
          .and(to[:eff_to].gt(at_value).or(to[:eff_to].eq(TemporalTables::END_OF_TIME)))
          .and(to[:eff_from].lteq(at_value))
      end
      join
    end
  end
end

Arel::Table.prepend TemporalTables::ArelTable
