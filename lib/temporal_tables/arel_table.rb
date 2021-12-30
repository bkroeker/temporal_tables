module TemporalTables
  # This is required for eager_load to work in Rails 6.0
  module ArelTable
    def create_join(to, constraint = nil, klass = Arel::Nodes::InnerJoin)
      join = super
      if at_value = Thread.current[:at_time]
        join = join
          .and(to[:eff_to].gteq(at_value))
          .and(to[:eff_from].lteq(at_value))
      end
      join
    end
  end
end

unless Rails::VERSION::MAJOR < 6
  Arel::Table.prepend(TemporalTables::ArelTable)
end
