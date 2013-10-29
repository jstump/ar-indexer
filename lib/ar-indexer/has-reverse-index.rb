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
				module_function :on_create_record

				def on_update_record
					puts "Indexable record updated"
				end
				module_function :on_update_record

			end

		end

	end

end
