ActiveRecord::Schema.define do
	create_table :people, temporal: true, force: true do |t|
		t.references :coven
		t.string :name
	end

	create_table :covens, force: true do |t|
		t.string :name
	end
	add_temporal_table :covens

	create_table :warts, temporal: true, force: true do |t|
		t.references :person
		t.integer :hairiness
	end
end
