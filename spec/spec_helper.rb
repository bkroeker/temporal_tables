# frozen_string_literal: true

require 'gemika'
require 'combustion'
require 'yaml'

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].sort.each { |f| require f }
Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each { |f| require f }
READ_DATABASE_CONFIG_LOCATION = 'spec/internal/config/database.ci.yml'
WRITE_DATABASE_CONFIG_LOCATION = 'spec/internal/config/database.yml'

def database_config_from_gems(file_location)
  config = YAML.load_file(file_location)
  data = config.slice(TemporalTables::DatabaseHelper.adapter_name)
  { Rails.env.to_s => data }
end

original_env = Rails.env

puts database_config_from_gems(READ_DATABASE_CONFIG_LOCATION)
File.write(
  WRITE_DATABASE_CONFIG_LOCATION,
  database_config_from_gems(READ_DATABASE_CONFIG_LOCATION).to_yaml
)

Rails.env = TemporalTables::DatabaseHelper.adapter_name
database = Gemika::Database.new
database.connect

Gemika::RSpec.configure_clean_database_before_example
Rails.env = original_env

begin
  Combustion.initialize! :active_record
rescue ActiveRecord::RecordNotUnique
  # noop
end

RSpec.configure do |config|
  config.before do
    DatabaseCleaner.clean
  end
end
