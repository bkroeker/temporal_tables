# frozen_string_literal: true

class HamsterWheel < ActiveRecord::Base
  belongs_to :hamster, foreign_key: :hamster_uuid, primary_key: :uuid, inverse_of: :hamster_wheel
end
