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
        # assume the record's effective to date minus 1 microsecond
        super.at(@owner.at_value || (@owner.eff_to - TemporalTables::ONE_MICROSECOND))
      else
        super
      end
    end

    # There seems to be an issue with the statement cache for history associations.
    # This may be due to the at_value not being part of how the relations are hashed,
    # or that the cached statements are not parameterized. Will require further investigation.
    # In the meantime, we can workaround this issue by disabling the statement cache for History queries.
    def skip_statement_cache?(scope)
      klass.is_a?(TemporalTables::TemporalClass::ClassMethods) || super(scope)
    end
  end
end

ActiveRecord::Associations::Association.prepend TemporalTables::AssociationExtensions
