require 'spec_helper'

describe Person do
	let(:emily) { Person.create name: "Emily" }
	let(:historical_emily) { emily.history.last }

	before do
		emily
		@init_time = Time.now
		sleep 0.1
	end

	describe "upon making significant life changes" do
		let!(:coven) { Coven.create name: "Double Double Toil & Trouble" }
		let!(:wart) { Wart.create person: emily, hairiness: 3 }

		before do
			emily.update_attributes name: "Grunthilda", coven: coven
			sleep 0.1
		end

		describe "when affirming changes" do
			it "should have new name" do
				expect(emily.name).to eq("Grunthilda")
				expect(historical_emily.name).to eq("Grunthilda")
			end

			it "should belong to coven" do
				expect(emily.coven.name).to eq(coven.name)
				expect(historical_emily.coven.name).to eq(coven.name)
			end

			it "should have a wart" do
				expect(emily.warts).to eq([wart])
				expect(emily.history.at(Time.now).last.warts).to eq([wart.history.last])
			end

			it "should allow scopes on associations" do
				expect(emily.warts.very_hairy).to eq([wart])
				expect(historical_emily.warts.very_hairy).to eq([wart.history.last])
			end
		end

		describe "when reflecting on the past" do
			let(:orig_emily) { emily.history.at(@init_time).last }

			it "should have historical name" do
				expect(orig_emily.name).to eq("Emily")
				expect(orig_emily.at_value).to eq(@init_time)
			end

			it "should not belong to a coven or have warts" do
				expect(orig_emily.coven).to eq(nil)
				expect(orig_emily.warts.count).to eq(0)
			end
		end

		describe "when preloading associations" do
			let(:orig_emily) { emily.history.at(@init_time).preload(:warts).first }

			it 'should preload the correct time' do
				expect(orig_emily.warts).to be_empty
			end
		end

		describe "when eager_loading associations" do
			let(:orig_emily) { emily.history.at(@init_time).eager_load(:warts).first }

			it 'should include the correct time' do
				expect(orig_emily.warts).to be_empty
			end
		end

		describe "when checking simple code values" do
			it "should have correct class names" do
				expect(emily.class.name).to eq("Person")
				expect(historical_emily.class.name).to eq("PersonHistory")

				expect(Person.history).to eq(PersonHistory)
			end

			it "should have correct class hierarchies" do
				expect(emily.is_a?(Person)).to eq(true)
				expect(emily.is_a?(PersonHistory)).to eq(false)

				expect(historical_emily.is_a?(Person)).to eq(true)
				expect(historical_emily.is_a?(PersonHistory)).to eq(true)
			end
		end
	end
end
