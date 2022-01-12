# frozen_string_literal: true

class Wart < ActiveRecord::Base
  belongs_to :person

  scope :very_hairy, lambda {
    where(arel_table[:hairiness].gteq(3))
  }
end
