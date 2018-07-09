module TemporalTables
	module NamedExtensionsWithHistory
		def scope(name, body, &block)
			if history
				history_body = -> { history.instance_exec &body }
				history.scope_without_history name, history_body, &block
			end
			super name, body, &block
		end
	end
end

ActiveRecord::Scoping::Named::ClassMethods.send :prepend, TemporalTables::NamedExtensionsWithHistory
