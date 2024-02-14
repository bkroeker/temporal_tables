# frozen_string_literal: true

class Hamster < ActiveRecord::Base
  self.primary_key = :uuid

  has_one :hamster_wheel, foreign_key: :hamster_uuid, inverse_of: :hamster
end
