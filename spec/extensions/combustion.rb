class Combustion::Database::Reset
	def configuration
		adapter = TemporalTables::DatabaseAdapter.adapter_name
		ActiveRecord::Base.configurations[adapter]
	end
end

class Combustion::Databases::MySQL
	def reset
		super
		establish_connection TemporalTables::DatabaseAdapter.adapter_name.to_sym
	end
end
