module ARIndexer

  class ReverseIndex < ::ActiveRecord::Base

    attr_accessible :id_list, :model_name, :word

    validates_uniqueness_of :word, :scope => :model_name

    # Retrieves the id_list property as a parsed array of integers
    # 
    # ==== Returns
    # 
    # array of integer

    def retrieve_id_array
      id_array = self.id_list.split(',')
      id_array.map! {|id| id.to_i}
      return id_array
    end

  end

end
