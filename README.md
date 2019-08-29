# TemporalTables

Easily recall what your data looked like at any point in the past!  TemporalTables sets up and maintains history tables to track all temporal changes to to your data.

Currently tested on Ruby 2.5.4, Rails 5.0 - 6.0, Postgres 11.3, MySQL 8.0.13

## Installation

Add this line to your application's Gemfile:
``` ruby
gem 'temporal_tables'
```

And then execute:
``` bash
$ bundle
```

Or install it yourself as:
``` bash
$ gem install temporal_tables
```

## Usage

### Schema

In your rails migration, specify that you want a table to have its history tracked:
``` ruby
create_table :people, temporal: true do |t|
  ...
end
```

This will create a history table called "people_h" which will maintain a history of all changes to any records in people with the use of triggers on any create/update/delete operation.

Any subsequent schema changes to people will be reflected automatically in people_h.

``` ruby
# Nothing extra required -- people_h will automatically get an "name" column too!
add_column :people, :name, :string
```

To track the history of a pre-existing table, just call `add_temporal_table`:
``` ruby
add_temporal_table :people
```

### Querying

For the below queries, we'll assume the following schema:
``` ruby
class Person < ActiveRecord::Base
  belongs_to :coven, optional: true
  has_many :warts

  def to_s
    parts = [name]
    parts << "from #{coven.name}" if coven
    parts.join ' '
  end
end

class Coven < ActiveRecord::Base
  has_many :members, class_name: "Person"

  def to_s
    name
  end
end

class Wart < ActiveRecord::Base
  belongs_to :person

  scope :very_hairy, -> { where(arel_table[:num_hairs].gteq(3)) }

  def to_s
    "wart on #{location} with #{pluralize num_hairs, 'hair'}"
  end
end
```

You can query the history tables by calling `history` on the class.
``` ruby
Person         #=> Person(id: :integer, name: :string)
Person.history #=> PersonHistory(history_id: :integer, id: :integer, name: :string, eff_from: :datetime, eff_to: :datetime)
```

You can easily get a history of all changes to a records.
``` ruby
Person.history.where(id: 1).map { |p| "#{p.eff_from}: #{p.to_s}")
# => [
#  "1974-01-14: Emily",
#  "2003-11-03: Grunthilda from Delta Gamma Gamma"
# ]
```

You can query for records as they were at any point in the past by calling `at`.
``` ruby
 Person.history.at(2.years.ago).where(id: 1).first.name #=> "Grunthilda"
```

Associations work too.
``` ruby
grunthilda = Person.history.at(20.years.ago).find_by_name("Grunthilda")
grunthilda.warts.count            #=> 2

grunthilda = Person.history.at(1.year.ago).find_by_name("Grunthilda")
grunthilda.warts.count            #=> 13

grunthilda.warts.first.class.name #=> "WartHistory"
```

And scopes also!
``` ruby
grunthilda = Person.history.at(1.year.ago).find_by_name("Grunthilda")
grunthilda.warts.count            #=> 13
grunthilda.warts.very_hairy.count #=> 7
```

Instance methods are inherited.
``` ruby
grunthilda.to_s                   #=> "Grunthilda from Delta Gamma Gamma"
grunthilda.class.name             #=> "PersonHistory"
grunthilda.class.superclass.name  #=> "Person"
```

## Config
You can configure temporal_tables in an initializer.

Create temporal tables for all tables by default (default = false)
``` ruby
TemporalTables.create_by_default = true
```

Don't create temporal tables for these tables.  (default = %w{schema_migrations sessions ar_internal_metadata})
``` ruby
TemporalTables.skip_temporal_table_for :table_one, :table_two
```

Add an `updated_by` column to all temporal tables to track who made any changes, which is quite useful for auditing.  Defaults to a :string field.  The block is called when records are saved to determine the value to place within the `updated_by` field.  `updated_by` fields are only auto-created if this is configured.
``` ruby
TemporalTables.add_updated_by_field(:integer) { User.current_user&.id }
```

## Copyright
See [LICENSE](https://github.com/bkroeker/temporal_tables/blob/master/LICENSE.txt) for more details.
