# frozen_string_literal: true

require 'spec_helper'

describe TemporalTables::TemporalAdapter do
  describe '#remove_temporal_table' do
    it 'correctly removes history table, functions and triggers' do
      skip 'mysql has no functions' if TemporalTables::DatabaseHelper.adapter_name == 'mysql'

      expect do
        ActiveRecord::Schema.define { remove_temporal_table :people }
      end.to change { TemporalTables::DatabaseHelper.table_exists?('people_h') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.function_exists?('people_ai()') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.function_exists?('people_au()') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.function_exists?('people_ad()') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.trigger_exists?('people_ai') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.trigger_exists?('people_au') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.trigger_exists?('people_ad') }.from(true).to(false)
    end

    it 'correctly removes history table and triggers' do
      skip 'other adapters than mysql have functions, too' if TemporalTables::DatabaseHelper.adapter_name != 'mysql'

      expect do
        ActiveRecord::Schema.define { remove_temporal_table :people }
      end.to change { TemporalTables::DatabaseHelper.table_exists?('people_h') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.trigger_exists?('people_ai') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.trigger_exists?('people_au') }.from(true).to(false)
         .and change { TemporalTables::DatabaseHelper.trigger_exists?('people_ad') }.from(true).to(false)
    end
  end
end
