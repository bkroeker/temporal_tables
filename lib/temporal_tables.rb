require "temporal_tables/temporal_adapter"
require "temporal_tables/connection_adapters/mysql_adapter"
require "temporal_tables/connection_adapters/postgresql_adapter"
require "temporal_tables/whodunnit"
require "temporal_tables/temporal_class"
require "temporal_tables/history_hook"
require "temporal_tables/relation_extensions"
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

			ActiveRecord::Base.send :include, TemporalTables::Whodunnit
		end
	end

	@@create_by_default = false
	def self.create_by_default
		@@create_by_default
	end
	def self.create_by_default=(default)
		@@create_by_default = default
	end

	@@skipped_temporal_tables = [:schema_migrations, :sessions]
	def self.skip_temporal_table_for(*tables)
		@@skipped_temporal_tables += tables
	end
	def self.skipped_temporal_tables
		@@skipped_temporal_tables.dup
	end

	@@add_updated_by_field = false
	@@updated_by_type = :string
	@@updated_by_proc = nil
	def self.updated_by_type
		@@updated_by_type
	end
	def self.updated_by_proc
		@@updated_by_proc
	end
	def self.add_updated_by_field(type = :string, &block)
		if block_given?
			@@add_updated_by_field = true
			@@updated_by_type = type
			@@updated_by_proc = block
		end

		@@add_updated_by_field
	end
end
