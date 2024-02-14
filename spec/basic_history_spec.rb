# frozen_string_literal: true

require 'spec_helper'

describe Person do
  let(:emily) { Person.create name: 'Emily' }
  let(:historical_emily) { emily.history.last }

  before do
    emily
    @init_time = Time.zone.now
    sleep 0.1
  end

  describe 'upon making significant life changes' do
    let!(:coven) { Coven.create name: 'Double Double Toil & Trouble' }
    let!(:wart) { Wart.create person: emily, hairiness: 3 }

    before do
      emily.update name: 'Grunthilda', coven: coven
      sleep 0.1
    end

    describe 'when affirming changes' do
      it 'should have new name' do
        expect(emily.name).to eq('Grunthilda')
        expect(historical_emily.name).to eq('Grunthilda')
      end

      it 'should belong to coven' do
        expect(emily.coven.name).to eq(coven.name)
        expect(historical_emily.coven.name).to eq(coven.name)
      end

      it 'should have a wart' do
        expect(emily.warts).to eq([wart])
        expect(emily.history.at(Time.zone.now).last.warts).to eq([wart.history.last])
      end

      it 'should allow scopes on associations' do
        expect(emily.warts.very_hairy).to eq([wart])
        expect(historical_emily.warts.very_hairy).to eq([wart.history.last])
      end

      it 'should allow at value on class too' do
        expect(Wart.history.at(Time.zone.now).where(person: emily).count).to eq(1)
        expect(Wart.history.at(1.minute.ago).where(person: emily).count).to eq(0)
      end
    end

    describe 'when reflecting on the past' do
      let(:orig_emily) { emily.history.at(@init_time).last }

      it 'should have historical name' do
        expect(orig_emily.name).to eq('Emily')
        expect(orig_emily.at_value).to eq(@init_time)
      end

      it 'should not belong to a coven or have warts' do
        expect(orig_emily.coven).to eq(nil)
        expect(orig_emily.warts.count).to eq(0)
      end
    end

    describe 'when preloading associations' do
      let(:orig_emily) { emily.history.at(@init_time).preload(:warts).first }

      it 'should preload the correct time' do
        expect(orig_emily.warts).to be_empty
      end
    end

    describe 'when eager_loading associations' do
      let(:orig_emily) { emily.history.at(@init_time).eager_load(:warts).first }

      it 'should include the correct time' do
        expect(orig_emily.warts).to be_empty
      end

      it 'should generate sensible sql' do
        sql =
          emily
          .history
          .at(@init_time)
          .eager_load(:warts)
          .where(Wart.history.arel_table[:hairiness].gteq(2))
          .to_sql
          .split(/(FROM)|(WHERE)|(ORDER)/)
        from = sql[2]
        where = sql[4]

        expect(from.scan(/.warts_h.\..eff_from./i).count).to eq(1)
        expect(from.scan(/.warts_h.\..eff_to./i).count).to eq(2)

        expect(where.scan(/.people_h.\..eff_from./i).count).to eq(1)
        expect(where.scan(/.people_h.\..eff_to./i).count).to eq(2)
        expect(where.scan(/.warts_h.\..eff_from./i).count).to eq(0)
        expect(where.scan(/.warts_h.\..eff_to./i).count).to eq(0)
      end
    end

    describe 'when checking simple code values' do
      it 'should have correct class names' do
        expect(emily.class.name).to eq('Person')
        expect(historical_emily.class.name).to eq('PersonHistory')

        expect(Person.history).to eq(PersonHistory)
      end

      it 'should have correct class hierarchies' do
        expect(emily.is_a?(Person)).to eq(true)
        expect(emily.is_a?(PersonHistory)).to eq(false)

        expect(historical_emily.is_a?(Person)).to eq(true)
        expect(historical_emily.is_a?(PersonHistory)).to eq(true)
      end
    end

    describe 'when checking current state' do
      it 'should have correct information' do
        # ie. we shouldn't break regular ActiveRecord behaviour
        expect(Person.count).to eq(1)
        expect(Wart.count).to eq(1)

        emily = Person.first
        expect(emily.warts.count).to eq(1)
        expect(emily.warts.first.hairiness).to eq(3)

        emily = Person.where(id: emily.id).eager_load(:warts).first
        expect(emily.warts.count).to eq(1)
        expect(emily.warts.first.hairiness).to eq(3)
      end
    end

    # This test is to cover the StatementCache issue being worked around by the monkey patch in AssociationExtensions
    describe 'when making multiple association queries with different at values for different data' do
      it 'the correct data should be returned' do
        sabrina = Person.create name: 'Sabrina'
        sabrina_wart = Wart.create person: sabrina
        sabrina_wart.history.at(Time.current).first.person

        willow = Person.create name: 'Willow'
        willow_wart = Wart.create person: willow
        current_willow = willow_wart.history.at(Time.current).first.person

        expect(current_willow.name).to eq('Willow')
      end
    end

    describe 'when working with STI one level deep' do
      let!(:broom) { Broom.create person: emily, model: 'Cackler 2000' }

      it 'should initialize model correctly' do
        expect(emily.history.last.flying_machines).to eq([broom.history.last])
      end
    end

    describe 'when working with STI two levels deep' do
      let!(:rocket_broom) { RocketBroom.create person: emily, model: 'Pyrocackler 3000X' }

      it 'should initialize model correctly' do
        expect(emily.history.last.flying_machines).to eq([rocket_broom.history.last])
      end
    end
  end

  # The following only tests non-integer ids for postgres (see schema.rb)
  describe 'when spawning and aging a creature with a non-integer id' do
    let!(:cat) { Cat.create name: 'Mr. Mittens', color: 'black' }

    before do
      cat.lives.create started_at: 3.years.ago
      @init_time = Time.zone.now
      cat.update name: 'Old Mr. Mittens'
      cat.lives.first.update ended_at: Time.zone.now, death_reason: 'fell into cauldron'
      cat.lives.create started_at: Time.zone.now
    end

    # The following tests enum type columns for postgres
    it 'breed is set correctly' do
      expect(cat.breed).to eq('ragdoll')
      expect(cat.history.last.breed).to eq('ragdoll')
    end

    it 'shows one life at the beginning' do
      expect(cat.history.at(@init_time).last.lives.size).to eq(1)
    end

    it 'shows two lives at the end' do
      expect(cat.history.last.lives.size).to eq(2)
    end
  end

  # The following tests PKs with names other than "id"
  describe 'when spawning and renaming a creature with PK not named id' do
    let!(:dog) { Dog.create name: 'Fido' }

    context 'when Fido is renamed to Max' do
      before do
        dog.name = 'Max'
        dog.save!
      end

      it 'name is set correctly and we remember Max\'s original name' do
        expect(dog.name).to eq('Max')
        expect(dog.history.last.name).to eq('Max')

        fido = dog.history.first
        expect(fido.name).to eq('Fido')
        expect(fido.orig_obj.name).to eq('Max')
      end

      it 'at the exact time of the name change, the dog should not be both Max and Fido' do
        dog_at_moment_of_name_change = dog.history.at(dog.history.last.eff_from)
        expect(dog_at_moment_of_name_change.count).to eq(1)
        expect(dog_at_moment_of_name_change.first.name).to eq('Max')
      end

      context 'when Max is rehomed' do
        before do
          dog.destroy!
        end

        it 'Max is no longer home but Max/Fido lives on in our memories' do
          expect(Dog.count).to eq(0)
          expect(dog.history.last.name).to eq('Max')
          expect(dog.history.first.name).to eq('Fido')
        end
      end
    end
  end

  describe 'when removing a creature' do
    let!(:wart) { Wart.create person: emily, hairiness: 3 }

    before do
      emily.destroy!
      sleep 0.1
    end

    it 'destroys associated warts and we remember the historical association' do
      expect(emily).to be_destroyed
      expect { wart.reload }.to raise_error(ActiveRecord::RecordNotFound) # as it belonged to emily

      wart_h = wart.history.last # the last version of the wart
      expect(wart_h).to be_present

      emily_h = wart_h.person
      expect(emily_h).to be_present # we should be able to tell what person our wart belonged to
    end
  end
end

describe Bird do
  context 'when a bird and nest exist' do
    let(:bird) { Bird.create name: 'Sam' }
    let(:nest) { Bird::Nest.create bird: bird, height: 100 }

    it 'can create instance of class with nested class name with history entries' do
      expect(bird).not_to be_nil
      expect(nest).not_to be_nil
      expect(bird.history.first).not_to be_nil
      expect(nest.history.first).not_to be_nil
    end
  end
end

describe Hamster do
  context 'when a hamster and wheel exist' do
    let(:hamster) { Hamster.create name: 'Fluffy' }
    let(:wheel) { HamsterWheel.create hamster: hamster }

    it 'can create instance of class with nested class name with history entries' do
      expect(hamster).not_to be_nil
      expect(wheel).not_to be_nil
      expect(hamster.hamster_wheel).not_to be_nil
      hamster_history = Hamster.history.at(Time.now.utc).first
      expect(hamster_history).not_to be_nil
      expect(hamster_history.hamster_wheel).not_to be_nil
    end
  end
end
