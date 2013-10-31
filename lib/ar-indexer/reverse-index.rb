module ARIndexer

	class ReverseIndex < ::ActiveRecord::Base

		validates_uniqueness_of :word, :scope => :model_name

		def retrieve_id_array
			id_array = self.id_list.split(',')
			id_array.map! {|id| id.to_i}
			return id_array
		end

	end

end
