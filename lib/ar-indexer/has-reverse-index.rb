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

				def array_of_values_to_index
					values_for_indexing = []
					self.indexed_fields.each do |f|
						if ['string', 'text'].include? self.class.columns_hash[f.to_s].type.to_s
							values_for_indexing << self.read_attribute(f.to_s)
						end
					end
					return values_for_indexing
				end

				def on_create_record
					if !self.indexed_fields.empty?
						values_for_indexing = array_of_values_to_index
						Indexer.build_reverse_index(self.class.to_s.split('::').last.to_s, self.id, values_for_indexing, false)
					end
				end

				def on_update_record
					if !self.indexed_fields.empty?
						values_for_indexing = array_of_values_to_index
						Indexer.build_reverse_index(self.class.to_s.split('::').last.to_s, self.id, values_for_indexing, true)
					end
				end

			end

		end

	end

end
