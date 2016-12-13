module TemporalTables::DatabaseAdapter
	def self.adapter_name
		if Gemika::Env.gem?('pg')
			"postgresql"
		elsif Gemika::Env.gem?('mysql2')
			"mysql"
		end
	end
end
