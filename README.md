# TemporalTables

Easily recall what your data looked like at any point in the past!  TemporalTables sets up and maintains history tables to track all temporal changes to to your data.

## Installation

Add this line to your application's Gemfile:

    gem 'temporal_tables'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install temporal_tables

## Usage

In your rails migration, specify that you want a table to have its history tracked:

 create_table :foo, :temporal => true do |t|
 	 ...
 end

This will create a history table called "foo_h" which will maintain a history of all changes to any records in foo with the use of triggers on any create/update/delete operation.

Any subsequent schema changes to foo will be reflected automatically in foo_h.

 # Nothing extra required -- foo_h will automatically get a "bar" column too!
 add_column :foo, :bar, :string

## Config

Create temporal tables for all tables by default
 TemporalTables.create_by_default = true

Don't create temporal tables for these tables.  Defaults to schema_migrations and sessions tables.
 TemporalTables.skip_temporal_table_for :table_one, :table_two

Add an updated_by field to all temporal tables to track who made any changes.  Defaults to a :string field.  The block is called when records are saved to determine the value to place within the updated_by field.
 TemporalTables.add_updated_by_field(:integer) { User.current_user.try(:id) }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
