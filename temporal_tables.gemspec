# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'temporal_tables/version'

Gem::Specification.new do |gem|
  gem.name          = "temporal_tables"
  gem.version       = TemporalTables::VERSION
  gem.authors       = ["Brent Kroeker"]
  gem.email         = ["brent@bkroeker.com"]
  gem.description   = %q{Easily recall what your data looked like at any point in the past!  TemporalTables sets up and maintains history tables to track all temporal changes to to your data.}
  gem.summary       = %q{Tracks all history of changes to a table automatically in a history table.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "rails", ">= 5.0", "< 6.2"
  gem.add_development_dependency "rspec", "~> 3.4"
  gem.add_development_dependency "combustion", "~> 0.9.1"
  gem.add_development_dependency "gemika"
end
