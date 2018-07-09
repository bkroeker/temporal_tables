module TemporalTables
	# This is mixed into all History classes.
	module TemporalClass
		def self.included(base)
			base.class_eval do
				base.extend ClassMethods

				self.table_name += "_h"

				cattr_accessor :visited_associations
				@@visited_associations = []

				# The at_value field stores the time from the query that yielded
				# this record.
				attr_accessor :at_value

				class << self
					prepend STIWithHistory
				end

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
							send(association.macro, association.name,
								association.options.merge(
									class_name:  clazz.name,
									foreign_key: association.foreign_key,
									primary_key: clazz.orig_class.primary_key
								)
							)
						end
					end
				end
			end
		end

		module STIWithHistory
			def sti_name
				super.sub /History$/, ""
			end

			def find_sti_class(type_name)
				sti_class = super(type_name)
				sti_class = sti_class.history unless sti_class.respond_to?(:orig_class)
				sti_class
			end
		end

		module ClassMethods
			def orig_class
				name.sub(/History$/, "").constantize
			end

			def descends_from_active_record?
				superclass.descends_from_active_record?
			end
		end

		def orig_class
			self.class.orig_class
		end

		def orig_id
			attributes[orig_class.primary_key]
		end

		def orig_obj
			@orig_obj ||= orig_class.find_by_id orig_id
		end

		def prev
			@prev ||= history.where(self.class.arel_table[:eff_from].lt(eff_from)).last
		end

		def next
			@next ||= history.where(self.class.arel_table[:eff_from].gt(eff_from)).first
		end
	end
end
