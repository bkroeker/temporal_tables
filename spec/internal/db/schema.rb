ActiveRecord::Schema.define do
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
end
