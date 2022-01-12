# frozen_string_literal: true

module TemporalTables
  # Uses the time from the "at" field stored in the record to filter queries
  # made to associations.
  module AssociationExtensions
    def target_scope
      # Kludge: Check +public_methods+ instead of using +responds_to?+ to
      # bypass +delegate_missing_to+ calls, as in +ActiveStorage::Attachment+.
      # Using responds_to? results in an infinite loop stack overflow.
      if @owner.public_methods.include?(:at_value)
        # If this is a history record but no at time was given,
        # assume the record's effective to date
        super.at(@owner.at_value || @owner.eff_to)
      else
        super
      end
    end
  end
end

ActiveRecord::Associations::Association.prepend TemporalTables::AssociationExtensions
