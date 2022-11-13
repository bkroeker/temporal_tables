# frozen_string_literal: true

begin
  postgres = ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
rescue NameError
  postgres = false
end

ActiveRecord::Schema.define do
  if postgres
    enable_extension 'pgcrypto'
    execute <<-SQL
      CREATE TYPE cat_breed AS ENUM ('ragdoll', 'persian', 'sphynx');
    SQL
  end

  create_table :covens, force: true do |t|
    t.string :name
  end
  add_temporal_table :covens

  create_table :people, temporal: true, force: true do |t|
    t.belongs_to :coven
    t.string :name
  end
  add_index :people, :name, unique: true

  create_table :warts, temporal: true, force: true do |t|
    t.belongs_to :person
  end
  add_column :warts, :hairiness, :integer

  create_table :flying_machines, temporal: true, force: true do |t|
    t.belongs_to :person
    t.string :type
    t.string :model
  end
  add_index :flying_machines, :model, unique: true
  remove_index :flying_machines, :model

  create_table :cats, id: (postgres ? :uuid : :integer), temporal: true, force: true do |t|
    t.string :name
    t.string :color
    t.column :breed, (postgres ? :cat_breed : :string), null: false, default: 'ragdoll'
  end

  create_table :cat_lives, id: (postgres ? :uuid : :integer), temporal: true do |t|
    t.belongs_to :cat, type: (postgres ? :uuid : :integer)
    t.timestamp :started_at
    t.timestamp :ended_at
    t.string :death_reason
  end

  create_table :dogs, primary_key: 'dog_id', temporal: true do |t|
    t.string :name
  end
  add_index :dogs, :name, name: 'name_index_with_a_name_that_happens_to_be_exactly_63_chars_long'
  remove_index :dogs, name: :name_index_with_a_name_that_happens_to_be_exactly_63_chars_long

  create_table :a_very_very_very_very_very_long_table_name, temporal: true do |t|
    t.string :name
  end
end
