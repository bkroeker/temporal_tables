class Combustion::Database::Reset
  def call
    configuration = resettable_db_configs[Rails.env]
    adapter = configuration["adapter"] ||
              configuration["url"].split("://").first

    operator_class(adapter).new(configuration).reset
  end
end
