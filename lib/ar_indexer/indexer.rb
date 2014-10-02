module ARIndexer
  module Indexer
    def self.break_string(value)
      # Remove HTML markup
      value.gsub!(/<[^>]+>/, ' ')
      # Decode HTML entities
      coder = HTMLEntities.new
      value = coder.decode(value)
      # Remove most punctuation
      value.gsub!(/[^a-zA-Z0-9\s]/, '')
      # Move everything to lower case
      value.downcase!
      # Split all words into an array
      forward_index = value.split(' ')
      # Remove stopwords and duplicates
      forward_index = (forward_index - Stopwords::STOPWORDS).uniq
      return forward_index
    end

    def self.index_string(model_name, object_id, field_name, value, repair_on_completion)
      forward_index = self.break_string(value)
      forward_index.each do |word|
        if reverse_index_record = ReverseIndex.where(model_name: model_name, field_name: field_name, word: word).first
          current_id_array = reverse_index_record.retrieve_id_array
          unless current_id_array.include? object_id
            new_id_list = (current_id_array << object_id).sort.join(',')
            reverse_index_record.update(id_list: new_id_list)
          end
        else
          ReverseIndex.create(model_name: model_name, field_name: field_name, word: word, id_list: object_id)
        end
      end
    end

    def self.remove_index(object_id)
      # 
    end

    def self.repair_index(model_name, object_id, field_name, forward_index)
      # 
    end
  end

  module Stopwords
    STOPWORDS = []
  end
end
