module ARIndexer
  class ReverseIndex < ::ActiveRecord::Base
    if ::ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :model_constant, :field_name, :word, :id_list
    end

    validates_uniqueness_of :word, :scope => [:model_constant, :field_name]

    def retrieve_id_array
      id_array = self.id_list.split(',')
      id_array.map! {|id| id.to_i}
      return id_array
    end
  end
end
