# frozen_string_literal: true

class Bird < ActiveRecord::Base
  has_one :nest, inverse_of: :bird
end
