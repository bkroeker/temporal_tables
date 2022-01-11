require "gemika"
require "combustion"
require "yaml"

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each { |f| require f }
READ_DATABASE_CONFIG_LOCATION = "spec/internal/config/database.ci.yml"
WRITE_DATABASE_CONFIG_LOCATION = "spec/internal/config/database.yml"

def adapter_name
  if Gemika::Env.gem?("mysql2")
    "mysql"
  else
    "postgresql"
  end
end

def database_config_from_gems(file_location)
  config = YAML.load_file(file_location)
  data = config.slice(adapter_name)
  {Rails.env.to_s => data}
end

original_env = Rails.env

puts database_config_from_gems(READ_DATABASE_CONFIG_LOCATION)
File.write(
  WRITE_DATABASE_CONFIG_LOCATION,
  database_config_from_gems(READ_DATABASE_CONFIG_LOCATION).to_yaml
)

Rails.env = adapter_name
database = Gemika::Database.new
database.connect

Gemika::RSpec.configure_clean_database_before_example
Rails.env = original_env

begin
  Combustion.initialize! :active_record
rescue ActiveRecord::RecordNotUnique => e
end

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean
  end
end
