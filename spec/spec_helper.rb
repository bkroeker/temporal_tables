require "gemika"
require "combustion"
require "yaml"

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each { |f| require f }
READ_DATABASE_CONFIG_LOCATION = "spec/internal/config/database.ci.yml"
WRITE_DATABASE_CONFIG_LOCATION = "spec/internal/config/database.yml"

def adapter_name
  if Gemika::Env.gem?("pg")
    "postgresql"
  elsif Gemika::Env.gem?("mysql2")
    "mysql"
  else
    "postgresql"
  end
end

def database_config_from_gems(file_location)
  config = YAML.load_file(file_location)
  {Rails.env.to_s => config.slice(adapter_name)}
end

File.write(
  WRITE_DATABASE_CONFIG_LOCATION,
  database_config_from_gems(READ_DATABASE_CONFIG_LOCATION).to_yaml
)

database = Gemika::Database.new
database.connect

Gemika::RSpec.configure_clean_database_before_example

begin
  Combustion.initialize! :active_record
rescue ActiveRecord::RecordNotUnique => e
end
# DatabaseCleaner.strategy = :deletion
RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean_with(:deletion)
  end
end
