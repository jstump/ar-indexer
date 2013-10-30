module ARIndexer

	module Model

		def self.included(base)
			base.send :extend, ClassMethods
		end

		module ClassMethods

			def has_reverse_index(fields = [])
				send :include, InstanceMethods

				class_attribute :indexed_fields
				self.indexed_fields = fields.dup

				after_create :on_create_record
				after_update :on_update_record
			end
			module_function :has_reverse_index

			module InstanceMethods

				private

				def on_create_record
					puts "Indexable record created"
				end

				def on_update_record
					puts "Indexable record updated"
				end

			end

		end

	end

end
