require "gemika"
require "combustion"
require "yaml"

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each { |f| require f }
DATABASE_CONFIG_LOCATION = "spec/internal/config/database.yml"

def adapter_name
  if Gemika::Env.gem?("pg")
    "postgresql"
  elsif Gemika::Env.gem?("mysql2")
    "mysql"
  end
end

def database_config_from_gems(file_location)
  config = YAML.load_file(file_location)
  config.slice(adapter_name)
end

original_env = Rails.env
File.write(DATABASE_CONFIG_LOCATION,
  database_config_from_gems(DATABASE_CONFIG_LOCATION).to_yaml)

Rails.env = adapter_name
Combustion.initialize! :active_record
DatabaseCleaner.strategy = :deletion
Rails.env = original_env

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean
  end
end
