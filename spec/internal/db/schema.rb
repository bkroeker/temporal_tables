postgres = ActiveRecord::Base.connection.class.name == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"

ActiveRecord::Schema.define do
  if postgres
    enable_extension "pgcrypto"
  end

  create_table :people, temporal: true, force: true do |t|
    t.belongs_to :coven
    t.string :name
  end

  create_table :covens, force: true do |t|
    t.string :name
  end
  add_temporal_table :covens

  create_table :warts, temporal: true, force: true do |t|
    t.belongs_to :person
    t.integer :hairiness
  end

  create_table :flying_machines, temporal: true, force: true do |t|
    t.belongs_to :person
    t.string :type
    t.string :model
  end

  create_table :cats, id: (postgres ? :uuid : :integer), temporal: true, force: true do |t|
    t.string :name
    t.string :color
  end

  create_table :cat_lives, id: (postgres ? :uuid : :integer), temporal: true do |t|
    t.belongs_to :cat, type: (postgres ? :uuid : :integer)
    t.timestamp :started_at
    t.timestamp :ended_at
    t.string :death_reason
  end
end
