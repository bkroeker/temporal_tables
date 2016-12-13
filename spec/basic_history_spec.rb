require 'spec_helper'

describe Person do
	let!(:person) { Person.create(name: "Emily") }

	describe "with a name change" do
		before do
			sleep 0.1
			person.update_attributes name: "Grunthilda"
		end

		it "should have new name" do
			expect(person.name).to eq("Grunthilda")
		end

		it "should have historical name" do
			expect(Person.history.first.name).to eq("Emily")
		end
	end
end
