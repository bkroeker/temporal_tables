# frozen_string_literal: true

module TemporalTables
  module Whodunnit
    def self.included(base)
      base.class_eval do
        include InstanceMethods

        before_validation :set_updated_by
      end
    end

    module InstanceMethods
      def set_updated_by
        return unless TemporalTables.updated_by_proc && respond_to?(:updated_by)

        self.updated_by = TemporalTables.updated_by_proc.call(self)
      end
    end
  end
end
