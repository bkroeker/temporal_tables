module TemporalTables
	# This is mixed into all History classes.
	module TemporalClass
		def self.included(base)
			base.class_eval do
				self.table_name += "_h"

				cattr_accessor :visited_associations
				@@visited_associations = []

				# The at_value field stores the time from the query that yielded
				# this record.
				attr_accessor :at_value

				# Iterates all associations, makes sure their history classes are 
				# created and initialized, and modifies the associations to point
				# to the target classes' history classes.
				def self.temporalize_associations!
					reflect_on_all_associations.dup.each do |association|
						unless @@visited_associations.include?(association.name) || association.options[:polymorphic]
							@@visited_associations << association.name

							# Calling .history here will ensure that the history class
							# for this association is created and initialized
							clazz = association.class_name.constantize.history

							# Recreate the association, updating it to point at the 
							# history class.  The foreign key is explicitly set since it's
							# inferred from the class_name, but shouldn't be in this case.
							create_reflection(
								association.macro, 
								association.name, 
								association.options.merge(
									class_name:  clazz.name, 
									foreign_key: association.foreign_key
								), 
								association.active_record
							)
						end
					end
				end

				# Delegate the at class method to the relation class.
				def self.at(*args)
					scoped.at(*args)
				end
			end
		end
	end
end
