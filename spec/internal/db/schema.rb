ActiveRecord::Schema.define do
	create_table :people, temporal: true, force: true do |t|
		t.string :name
	end

	# add_temporal_table :people
end
