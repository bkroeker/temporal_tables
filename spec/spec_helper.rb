require "gemika"
require "combustion"

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each { |f| require f }

original_env = Rails.env
adapter_name = if Gemika::Env.gem?("pg")
  "postgresql"
elsif Gemika::Env.gem?("mysql2")
  "mysql"
end
Rails.env = adapter_name
Combustion.initialize! :active_record
DatabaseCleaner.strategy = :deletion
Rails.env = original_env

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean
  end
end
