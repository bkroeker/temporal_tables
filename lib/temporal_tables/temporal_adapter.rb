module TemporalTables
	module TemporalAdapter
		def create_table(table_name, options = {}, &block)
			if options[:temporal_bypass]
				super table_name, options, &block
			else
				skip_table = TemporalTables.skipped_temporal_tables.include?(table_name.to_sym) || table_name.to_s =~ /_h$/

				super table_name, options do |t|
					block.call t

					if TemporalTables.add_updated_by_field && !skip_table
						t.column :updated_by, TemporalTables.updated_by_type
					end
				end

				if options[:temporal] || (TemporalTables.create_by_default && !skip_table)
					add_temporal_table table_name, options
				end
			end
		end

		def add_temporal_table(table_name, options = {})
			create_table temporal_name(table_name), options.merge(id: false, primary_key: "history_id", temporal_bypass: true) do |t|
				t.integer   :id
				t.datetime :eff_from, :null => false, limit: 6
				t.datetime :eff_to,   :null => false, limit: 6, :default => "9999-12-31"

				for c in columns(table_name)
					t.send c.type, c.name, :limit => c.limit
				end
			end

			if TemporalTables.add_updated_by_field && !column_exists?(table_name, :updated_by)
				change_table table_name do |t|
					t.column :updated_by, TemporalTables.updated_by_type
				end
			end

			add_index temporal_name(table_name), [:id, :eff_to]
			create_temporal_triggers table_name
			create_temporal_indexes table_name
		end

		def remove_temporal_table(table_name)
			if table_exists?(temporal_name(table_name))
				drop_temporal_triggers table_name
				drop_table_without_temporal temporal_name(table_name)
			end
		end

		def drop_table(table_name, options = {})
			super table_name, options

			if table_exists?(temporal_name(table_name))
				super temporal_name(table_name), options
			end
		end

		def rename_table(name, new_name)
			if table_exists?(temporal_name(name))
				drop_temporal_triggers name
			end

			super name, new_name

			if table_exists?(temporal_name(name))
				super temporal_name(name), temporal_name(new_name)
				create_temporal_triggers new_name
			end
		end

		def add_column(table_name, column_name, type, options = {})
			super table_name, column_name, type, options

			if table_exists?(temporal_name(table_name))
				super temporal_name(table_name), column_name, type, options
				create_temporal_triggers table_name
			end
		end

		def remove_column(table_name, *column_names)
			super table_name, *column_names

			if table_exists?(temporal_name(table_name))
				super temporal_name(table_name), *column_names
				create_temporal_triggers table_name
			end
		end

		def change_column(table_name, column_name, type, options = {})
			super table_name, column_name, type, options

			if table_exists?(temporal_name(table_name))
				super temporal_name(table_name), column_name, type, options
				# Don't need to update triggers here...
			end
		end

		def rename_column(table_name, column_name, new_column_name)
			super table_name, column_name, new_column_name

			if table_exists?(temporal_name(table_name))
				super temporal_name(table_name), column_name, new_column_name
				create_temporal_triggers table_name
			end
		end

		def add_index(table_name, column_name, options = {})
			super table_name, column_name, options

			if table_exists?(temporal_name(table_name))
				column_names = Array.wrap(column_name)
				idx_name = temporal_index_name(options[:name] || index_name(table_name, :column => column_names))

				super temporal_name(table_name), column_name, options.except(:unique).merge(name: idx_name)
			end
		end

		def remove_index(table_name, options = {})
			super table_name, options

			if table_exists?(temporal_name(table_name))
				idx_name = temporal_index_name(index_name(table_name, options))

				super temporal_name(table_name), :name => idx_name
			end
		end

		def create_temporal_indexes(table_name)
			indexes = ActiveRecord::Base.connection.indexes(table_name)

			indexes.each do |index|
				index_name = temporal_index_name(index.name)

				unless temporal_index_exists?(table_name, index_name)
					add_index(
						temporal_name(table_name),
						index.columns, {
							# exclude unique constraints for temporal tables
							:name   => index_name,
							:length => index.lengths,
							:order  => index.orders
					})
				end
			end
		end

		def temporal_name(table_name)
			"#{table_name}_h"
		end

		def create_temporal_triggers(table_name)
			raise NotImplementedError, "create_temporal_triggers is not implemented"
		end

		def drop_temporal_triggers(table_name)
			raise NotImplementedError, "drop_temporal_triggers is not implemented"
		end

		# It's important not to increase the length of the returned string.
		def temporal_index_name(index_name)
			index_name.to_s.sub(/^index/, "ind_h").sub(/_ix(\d+)$/, '_hi\1')
		end

		def temporal_index_exists?(table_name, index_name)
			raise "Rails version not supported" unless Rails::VERSION::MAJOR == 5
			case Rails::VERSION::MINOR
			when 0
				index_name_exists?(temporal_name(table_name), index_name, false)
			else
				index_name_exists?(temporal_name(table_name), index_name)
			end
		end
	end
end
