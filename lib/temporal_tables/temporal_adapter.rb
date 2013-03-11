module TemporalTables
	module TemporalAdapter
		def self.included(base)
			base.class_eval do
				alias_method_chain :create_table,  :temporal
				alias_method_chain :drop_table,    :temporal
				alias_method_chain :rename_table,  :temporal
				alias_method_chain :add_column,    :temporal
				alias_method_chain :remove_column, :temporal
				alias_method_chain :change_column, :temporal
				alias_method_chain :add_index,     :temporal
				alias_method_chain :remove_index,  :temporal

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

			end
		end

		def create_table_with_temporal(table_name, options = {}, &block)
			skip_table = TemporalTables.skipped_temporal_tables.include?(table_name.to_sym) || table_name.to_s =~ /_h$/

			create_table_without_temporal table_name, options do |t|
				block.call t

				if TemporalTables.add_updated_by_field && !skip_table
					t.column :updated_by, TemporalTables.updated_by_type
				end
			end

			if options[:temporal] || (TemporalTables.create_by_default && !skip_table)
				add_temporal_table table_name, options
			end
		end

		def add_temporal_table(table_name, options = {})
			create_table_without_temporal temporal_name(table_name), options.merge(:primary_key => "history_id") do |t|
				t.integer   :id
				t.timestamp :eff_from, :null => false
				t.timestamp :eff_to,   :null => false, :default => "9999-12-31"

				for c in columns(table_name)
					t.send c.type, c.name, :limit => c.limit
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
		
		def drop_table_with_temporal(table_name, options = {})
			drop_table_without_temporal table_name, options

			if table_exists?(temporal_name(table_name))
				drop_table_without_temporal temporal_name(table_name), options
			end
		end

		def rename_table_with_temporal(name, new_name)
			if table_exists?(temporal_name(name))
				drop_temporal_triggers name
			end

			rename_table_without_temporal name, new_name

			if table_exists?(temporal_name(name))
				rename_table_without_temporal temporal_name(name), temporal_name(new_name)
				create_temporal_triggers new_name
			end
		end

		def add_column_with_temporal(table_name, column_name, type, options = {})
			add_column_without_temporal table_name, column_name, type, options

			if table_exists?(temporal_name(table_name))
				add_column_without_temporal temporal_name(table_name), column_name, type, options
				create_temporal_triggers table_name
			end
		end

		def remove_column_with_temporal(table_name, *column_names)
			remove_column_without_temporal table_name, *column_names

			if table_exists?(temporal_name(table_name))
				remove_column_without_temporal temporal_name(table_name), *column_names
				create_temporal_triggers table_name
			end
		end

		def change_column_with_temporal(table_name, column_name, type, options = {})
			change_column_without_temporal table_name, column_name, type, options

			if table_exists?(temporal_name(table_name))
				change_column_without_temporal temporal_name(table_name), column_name, type, options
				# Don't need to update triggers here...
			end
		end

		def rename_column_with_temporal(table_name, column_name, new_column_name)
			rename_column_without_temporal table_name, column_name, new_column_name

			if table_exists?(temporal_name(table_name))
				rename_column_without_temporal temporal_name(table_name), column_name, new_column_name
				create_temporal_triggers table_name
			end
		end

		def add_index_with_temporal(table_name, column_name, options = {})
			add_index_without_temporal table_name, column_name, options

			if table_exists?(temporal_name(table_name))
				column_names = Array.wrap(column_name)
				idx_name = temporal_index_name(options[:name] || index_name(table_name, :column => column_names))

				add_index_without_temporal temporal_name(table_name), column_name, options.except(:unique).merge(name: idx_name)
			end
		end

		def remove_index_with_temporal(table_name, options = {})
			remove_index_without_temporal table_name, options

			if table_exists?(temporal_name(table_name))
				idx_name = temporal_index_name(index_name(table_name, options))
				
				remove_index_without_temporal temporal_name(table_name), :name => idx_name
			end
		end

		def create_temporal_indexes(table_name)
			indexes = ActiveRecord::Base.connection.indexes(table_name)

			indexes.each do |index|
				index_name = temporal_index_name(index[:name])

				unless index_name_exists?(temporal_name(table_name), index_name, false)
					add_index_without_temporal(
						temporal_name(table_name), 
						index[:columns], {
							# exclude unique constraints for temporal tables
							:name   => index_name, 
							:length => index[:lengths], 
							:order  => index[:orders]
					})
				end
			end
		end
	end
end
