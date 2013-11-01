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
				before_destroy :on_destroy_record
			end
			module_function :has_reverse_index

			module InstanceMethods

				private

				def array_of_values_to_index
					values_for_indexing = []
					if self.indexed_fields.empty?
						self.class.columns.each do |c|
							if ['string', 'text'].include? c.type.to_s
								values_for_indexing << self.read_attribute(c.name)
							end
						end
					else
						self.indexed_fields.each do |f|
							if ['string', 'text'].include? self.class.columns_hash[f.to_s].type.to_s
								values_for_indexing << self.read_attribute(f.to_s)
							end
						end
					end
					values_for_indexing.delete_if {|v| [nil, ''].include? v}
					return values_for_indexing
				end

				def on_create_record
					values_for_indexing = array_of_values_to_index
					unless values_for_indexing.empty?
						Indexer.build_reverse_index(self.class.to_s.split('::').last.to_s, self.id, values_for_indexing, false)
					end
				end

				def on_update_record
					values_for_indexing = array_of_values_to_index
					unless values_for_indexing.empty?
						Indexer.build_reverse_index(self.class.to_s.split('::').last.to_s, self.id, values_for_indexing, true)
					end
				end

				def on_destroy_record
					Indexer.remove_from_reverse_index(self.class.to_s.split('::').last.to_s, self.id)
				end

			end

		end

	end

end
