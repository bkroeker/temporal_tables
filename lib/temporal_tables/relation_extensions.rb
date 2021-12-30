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
      if Rails::VERSION::MAJOR < 6
        return get_value(:at) || Thread.current[:at_time]
      end

      @values.fetch(:at, nil) || Thread.current[:at_time]
    end

    def at_value=(value)
      if Rails::VERSION::MAJOR < 6
        set_value(:at, value)
      else
        @values[:at] = value
      end
    end

    def at(...)
      spawn.at!(...)
    end

    def at!(value)
      self.at_value = value
      where!(klass.build_temporal_constraint(value))
    end

    def to_sql(...)
      threadify_at do
        super(...)
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

    def limited_ids_for(...)
      threadify_at do
        super(...)
      end
    end

    def exec_queries
      # Note that record preloading, like when you specify
      #  MyClass.includes(:associations)
      # happens within this exec_queries call.  That's why we needed to
      # store the at_time in the thread above.
      #
      result = threadify_at { super }

      if historical?
        # Store the at value on each record returned
        result.each do |r|
          r.at_value = at_value
        end
      end

      result
    end

    def historical?
      table_name =~ /#{TemporalTables::TemporalClass::HISTORY_SUFFIX}$/i && at_value
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

ActiveRecord::Relation.prepend(TemporalTables::RelationExtensions)
