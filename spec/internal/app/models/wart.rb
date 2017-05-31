class Wart < ActiveRecord::Base
  belongs_to :person

  scope :very_hairy, -> {
    where(arel_table[:hairiness].gteq(3))
  }
end
