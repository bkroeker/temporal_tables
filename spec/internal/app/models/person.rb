class Person < ActiveRecord::Base
	belongs_to :coven
	has_many :warts
	has_many :flying_machines
end
