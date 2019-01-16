module TemporalTables
  # This hooks in a "history" method to ActiveRecord::Base which will
  # return the class's History class.  The history class extends the original
  # class, but runs against the history table to provide temporal results.
  #
  #  class Person < ActiveRecord::Base
  #    attr_accessible :name
  #  end
  #
  #  Person         #=> Person(id: integer, name: string)
  #  Person.history #=> PersonHistory(history_id: integer, id: integer, name: string, eff_from: datetime, eff_to: datetime)
  module HistoryHook
    def self.included(base)
      base.class_eval do
        # Return this class's history class.
        # If it doesn't exist yet, create and initialize it, as well
        # as all dependent classes (through associations).
        def self.history
          raise "Can't view history of history" if name =~ /History$/

          history_class = "#{name}History"
          history_class.constantize
        rescue NameError
          # If the history class doesn't exist yet, create it
          new_class = Class.new(self) do
            include TemporalTables::TemporalClass
          end
          segments = history_class.split("::")
          object_class = segments[0...-1].inject(Object) { |o, s| o.const_get(s) }
          object_class.const_set segments.last, new_class

          # Traverse associations and make sure they have
          # history classes too.
          history_class.constantize.temporalize_associations!
          history_class.constantize
        end
      end
    end

    # Returns a scope for the list of all history records for this
    # particular object.
    def history
      clazz = is_a?(TemporalTables::TemporalClass) ? self.class : self.class.history
      oid = is_a?(TemporalTables::TemporalClass) ? orig_class.primary_key : self.class.primary_key
      clazz.unscoped.where(id: attributes[oid]).order(:eff_from)
    end
  end
end

ActiveRecord::Base.send :include, TemporalTables::HistoryHook
