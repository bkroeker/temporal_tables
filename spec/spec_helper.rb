require 'gemika'
require 'combustion'

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].sort.each {|f| require f}
Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each {|f| require f}

Combustion.initialize! :active_record do
	Rails.env = TemporalTables::DatabaseAdapter.adapter_name
end

DatabaseCleaner.strategy = :deletion

RSpec.configure do |config|
	config.before(:each) do
		DatabaseCleaner.clean
	end
end
