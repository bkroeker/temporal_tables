require "temporal_tables/temporal_adapter"
require "temporal_tables/connection_adapters/mysql_adapter"
require "temporal_tables/connection_adapters/postgresql_adapter"
require "temporal_tables/version"

module TemporalTables
	class Railtie < ::Rails::Railtie
		initializer "temporal_tables.load" do
			# Iterating the subclasses will find any adapter implementations
			# which are in use by the rails app, and mixin the temporal functionality.
			# It's necessary to do this on the implementations in order for the
			# alias method chain hooks to work.
			ActiveRecord::ConnectionAdapters::AbstractAdapter.subclasses.each do |subclass|
				subclass.send :include, TemporalTables::TemporalAdapter

				module_name = subclass.name.split("::").last
				subclass.send :include, TemporalTables::ConnectionAdapters.const_get(module_name) if TemporalTables::ConnectionAdapters.const_defined?(module_name)
			end
		end
	end
end
