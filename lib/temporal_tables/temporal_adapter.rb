# frozen_string_literal: true

require 'digest'

module TemporalTables
  module TemporalAdapter # rubocop:disable Metrics/ModuleLength
    def create_table(table_name, **options, &block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      valid_options = options.except(:temporal, :temporal_bypass)
      if options[:temporal_bypass]
        super(table_name, **valid_options, &block)
      else
        skip_table = TemporalTables.skipped_temporal_tables.include?(table_name.to_sym) || table_name.to_s =~ /_h$/

        super(table_name, **valid_options) do |t|
          block.call t

          if TemporalTables.add_updated_by_field && !skip_table
            updated_by_already_exists = t.columns.any? { |c| c.name == 'updated_by' }
            if updated_by_already_exists
              puts "consider adding #{table_name} to TemporalTables skip_table" # rubocop:disable Rails/Output
            else
              t.column(:updated_by, TemporalTables.updated_by_type)
            end
          end
        end

        if options[:temporal] || (TemporalTables.create_by_default && !skip_table)
          add_temporal_table table_name, **options
        end
      end
    end

    def add_temporal_table(table_name, **options) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      create_table(
        temporal_name(table_name),
        **options.merge(id: false, primary_key: 'history_id', temporal_bypass: true)
      ) do |t|
        t.datetime :eff_from, null: false, limit: 6
        t.datetime :eff_to,   null: false, limit: 6, default: TemporalTables::END_OF_TIME

        columns(table_name).each do |c|
          column_options = { limit: c.limit, array: c.try(:array) }.compact
          column_type = c.type
          if column_type == :enum
            enum_type = c.sql_type_metadata.sql_type
            if t.respond_to?(:enum)
              column_options[:enum_type] = enum_type
            else
              column_type = enum_type
            end
          end

          t.column c.name, column_type, **column_options
        end
      end

      if TemporalTables.add_updated_by_field && !column_exists?(table_name, :updated_by)
        change_table table_name do |t|
          t.column :updated_by, TemporalTables.updated_by_type
        end
      end

      original_primary_key = original_primary_key(table_name)
      temporal_table_index_name = index_name(temporal_name(table_name), [original_primary_key, :eff_to])
      if temporal_table_index_name.length > index_name_length
        temporal_table_index_name = truncated_index_name(temporal_table_index_name)
      end
      add_index temporal_name(table_name), [original_primary_key, :eff_to], name: temporal_table_index_name
      create_temporal_triggers table_name, original_primary_key
      create_temporal_indexes table_name
    end

    def remove_temporal_table(table_name)
      return unless table_exists?(temporal_name(table_name))

      drop_temporal_triggers table_name
      drop_table temporal_name(table_name)

      return unless TemporalTables.add_updated_by_field && column_exists?(table_name, :updated_by)

      remove_column table_name, :updated_by
    end

    def drop_table(table_name, **options)
      super(table_name, **options)

      super(temporal_name(table_name), **options) if table_exists?(temporal_name(table_name))
    end

    def rename_table(name, new_name)
      drop_temporal_triggers name if table_exists?(temporal_name(name))

      super name, new_name

      return unless table_exists?(temporal_name(name))

      super(temporal_name(name), temporal_name(new_name))
      create_temporal_triggers new_name, original_primary_key(table_name)
    end

    def add_column(table_name, column_name, type, **options)
      super(table_name, column_name, type, **options)

      return unless table_exists?(temporal_name(table_name))

      super temporal_name(table_name), column_name, type, **options
      create_temporal_triggers table_name, original_primary_key(table_name)
    end

    def remove_columns(table_name, *column_names, **options)
      super(table_name, *column_names, **options)

      return unless table_exists?(temporal_name(table_name))

      super temporal_name(table_name), *column_names, **options
      create_temporal_triggers table_name, original_primary_key(table_name)
    end

    def remove_column(table_name, column_name, type = nil, **options)
      super(table_name, column_name, type, **options)

      return unless table_exists?(temporal_name(table_name))

      super temporal_name(table_name), column_name, type, **options
      create_temporal_triggers table_name, original_primary_key(table_name)
    end

    def change_column(table_name, column_name, type, **options)
      super(table_name, column_name, type, **options)

      return unless table_exists?(temporal_name(table_name))

      super temporal_name(table_name), column_name, type, **options
      # Don't need to update triggers here...
    end

    def rename_column(table_name, column_name, new_column_name)
      super(table_name, column_name, new_column_name)

      return unless table_exists?(temporal_name(table_name))

      super temporal_name(table_name), column_name, new_column_name
      create_temporal_triggers table_name, original_primary_key(table_name)
    end

    def add_index(table_name, column_name, **options)
      super(table_name, column_name, **options)

      return unless table_exists?(temporal_name(table_name))

      idx_name = temporal_index_name(options[:name] || index_name(table_name, column: column_name))
      super temporal_name(table_name), column_name, **options.except(:unique).merge(name: idx_name)
    end

    def remove_index(table_name, column_name = nil, **options)
      original_index_name = index_name_for_remove(table_name, column_name, options)
      super(table_name, column_name, **options)

      return unless table_exists?(temporal_name(table_name))

      idx_name = temporal_index_name(options[:name] || original_index_name)
      super temporal_name(table_name), column_name, name: idx_name
    end

    def create_temporal_indexes(table_name) # rubocop:disable Metrics/MethodLength
      indexes = ActiveRecord::Base.connection.indexes(table_name)

      indexes.each do |index|
        index_name = temporal_index_name(index.name)

        next if temporal_index_exists?(table_name, index_name)

        add_index(
          temporal_name(table_name),
          index.columns,
          # exclude unique constraints for temporal tables
          name: index_name,
          length: index.lengths,
          order: index.orders,
          using: index.using,
          opclass: index.opclasses
        )
      end
    end

    def temporal_name(table_name)
      "#{table_name}_h"
    end

    def create_temporal_triggers(_table_name)
      raise NotImplementedError, 'create_temporal_triggers is not implemented'
    end

    def drop_temporal_triggers(_table_name)
      raise NotImplementedError, 'drop_temporal_triggers is not implemented'
    end

    # Index names max out at 63 characters. If appending _h to the index name would surpass that limit,
    # we can trim the index name and append a deterministically generated 5 character hash as well as _h.
    def temporal_index_name(index_name)
      "#{index_name.length < 62 ? index_name : truncated_index_name(index_name, 2)}_h"
    end

    def truncated_index_name(index_name, required_padding = 0)
      max_length = index_name_length - required_padding
      index_name_hash = Digest::SHA1.base64digest(index_name.to_s)[0, 5]
      "#{index_name[0, max_length - 6]}_#{index_name_hash}"
    end

    def temporal_index_exists?(table_name, index_name)
      index_name_exists?(temporal_name(table_name), index_name)
    end

    def original_primary_key(table_name)
      original_primary_key = primary_key(table_name)
      raise 'temporal_adapter requires that the table has a single primary key' unless original_primary_key.is_a? String

      original_primary_key
    end
  end
end
