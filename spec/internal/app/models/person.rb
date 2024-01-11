# frozen_string_literal: true

class Person < ActiveRecord::Base
  belongs_to :coven
  has_many :warts, dependent: :destroy
  has_many :flying_machines
end
