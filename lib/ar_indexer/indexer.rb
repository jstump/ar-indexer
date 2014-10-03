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
        if index_record = ReverseIndex.where(model_name: model_name, field_name: field_name, word: word).first
          current_id_array = index_record.retrieve_id_array
          unless current_id_array.include? object_id
            new_id_list = (current_id_array << object_id).sort.join(',')
            index_record.update(id_list: new_id_list)
          end
        else
          ReverseIndex.create(model_name: model_name, field_name: field_name, word: word, id_list: object_id)
        end
      end
      repair_index(model_name, object_id, field_name, forward_index) if repair_on_completion
    end

    def self.remove_index_id(model_name, object_id)
      index_records = ReverseIndex.where(model_name: model_name)
      if index_records.count > 0
        index_records.each do |record|
          if record.id_list.match(/#{object_id},{0,1}/)
            current_id_array = record.retrieve_id_array
            if current_id_array.delete(object_id)
              if current_id_array.empty?
                record.destroy
              else
                new_id_list = current_id_array.join(',')
                record.update(id_list: new_id_list)
              end
            end
          end
        end
      end
    end

    def self.repair_index(model_name, object_id, field_name, forward_index)
      index_records = ReverseIndex.where(model_name: model_name, field_name: field_name)
      if index_records.count > 0
        index_records.each do |record|
          if record.id_list.match(/#{object_id},{0,1}/)
            unless forward_index.include?(record.word)
              current_id_array = record.retrieve_id_array
              if current_id_array.delete(object_id)
                if current_id_array.empty?
                  record.destroy
                else
                  new_id_list = current_id_array.join(',')
                  record.update(id_list: new_id_list)
                end
              end
            end
          end
        end
      end
    end
  end

  module Stopwords
    STOPWORDS = [
      "a",
      "about",
      "above",
      "after",
      "again",
      "against",
      "all",
      "am",
      "an",
      "and",
      "any",
      "are",
      "aren't",
      "as",
      "at",
      "be",
      "because",
      "been",
      "before",
      "being",
      "below",
      "between",
      "both",
      "but",
      "by",
      "can't",
      "cannot",
      "could",
      "couldn't",
      "did",
      "didn't",
      "do",
      "does",
      "doesn't",
      "doing",
      "don't",
      "down",
      "during",
      "each",
      "few",
      "for",
      "from",
      "further",
      "had",
      "hadn't",
      "has",
      "hasn't",
      "have",
      "haven't",
      "having",
      "he",
      "he'd",
      "he'll",
      "he's",
      "her",
      "here",
      "here's",
      "hers",
      "herself",
      "him",
      "himself",
      "his",
      "how",
      "how's",
      "i",
      "i'd",
      "i'll",
      "i'm",
      "i've",
      "if",
      "in",
      "into",
      "is",
      "isn't",
      "it",
      "it's",
      "its",
      "itself",
      "let's",
      "me",
      "more",
      "most",
      "mustn't",
      "my",
      "myself",
      "no",
      "nor",
      "not",
      "of",
      "off",
      "on",
      "once",
      "only",
      "or",
      "other",
      "ought",
      "our",
      "ours",
      "ourselves",
      "out",
      "over",
      "own",
      "same",
      "shan't",
      "she",
      "she'd",
      "she'll",
      "she's",
      "should",
      "shouldn't",
      "so",
      "some",
      "such",
      "than",
      "that",
      "that's",
      "the",
      "their",
      "theirs",
      "them",
      "themselves",
      "then",
      "there",
      "there's",
      "these",
      "they",
      "they'd",
      "they'll",
      "they're",
      "they've",
      "this",
      "those",
      "through",
      "to",
      "too",
      "under",
      "until",
      "up",
      "very",
      "was",
      "wasn't",
      "we",
      "we'd",
      "we'll",
      "we're",
      "we've",
      "were",
      "weren't",
      "what",
      "what's",
      "when",
      "when's",
      "where",
      "where's",
      "which",
      "while",
      "who",
      "who's",
      "whom",
      "why",
      "why's",
      "with",
      "won't",
      "would",
      "wouldn't",
      "you",
      "you'd",
      "you'll",
      "you're",
      "you've",
      "your",
      "yours",
      "yourself",
      "yourselves"
    ]
  end
end
