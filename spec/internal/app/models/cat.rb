# frozen_string_literal: true

class Cat < ActiveRecord::Base
  has_many :lives, class_name: 'CatLife'
end
