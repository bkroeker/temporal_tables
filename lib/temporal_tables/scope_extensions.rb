module TemporalTables
	module NamedExtensions
		def self.included(base)
			base.class_eval do
				alias_method_chain :scope, :history
			end
		end

		def scope_with_history(name, body, &block)
			if history
				history_body = -> { history.instance_exec &body }
				history.scope_without_history name, history_body, &block
			end
			scope_without_history name, body, &block
		end
	end
end

ActiveRecord::Scoping::Named::ClassMethods.send :include, TemporalTables::NamedExtensions
