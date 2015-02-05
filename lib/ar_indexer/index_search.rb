module ARIndexer
  module ARSearch
    class IndexSearch
      def initialize(models, opts = {})
        @models = {}
        models.each do |model|
          @models[model.to_s.split('::').last] = model
        end

        @options = {
          :fields => [],
          :match => :any,
          :sort => :relevance,
          :sort_method => nil,
          :sort_direction => :desc,
          :stopwords => [],
          :no_results_message => 'No results were returned for the given search term.'
        }
        @options.merge!(opts)
      end

      def search_models
        return @models.keys
      end

      def options(key)
        return @options[key]
      end

      def search(value)
        # Build array of words for query `reverse_indices.word IN ('word1', 'word2')`
        if @options[:match] == :any
          search_terms = ARSearch.expand_forward_index(Indexer.break_string(value), @options[:stopwords])
          enforce_threshold = false
        else
          stopwords = (Stopwords::STOPWORDS + @options[:stopwords]).uniq
          search_terms = (Indexer.break_string(value) - stopwords)
          enforce_threshold = true
        end

        # Execute AR query based on @options[:fields]
        if @options[:fields].empty?
          base_results = ReverseIndex.where(:model_constant => self.search_models, :word => search_terms)
        else
          base_results = ReverseIndex.where(:model_constant => self.search_models, :field_name => @options[:fields], :word => search_terms)
        end

        unless base_results.empty?
          return ARSearch.method("sort_by_#{@options[:sort]}".to_sym).call(base_results, self, search_terms.count)
        else
          return []
        end
      end

      def no_results_message
        return @options[:no_results_message]
      end
    end

    def self.expand_forward_index(forward_index, stopwords)
      # Stem and pluralize
      forward_index.each do |word|
        root = Stemmer::stem_word(word)
        unless forward_index.include? root
          forward_index = forward_index.inject([root], :<<)
        end
        plural = word.pluralize
        unless forward_index.include? plural
          forward_index = forward_index.inject([plural], :<<)
        end
      end
      
      # Remove stopwords and duplicates again
      stopwords = (Stopwords::STOPWORDS + stopwords).uniq
      forward_index = (forward_index - stopwords).uniq
      return forward_index
    end

    def self.get_object_counts(base_results, search_models, match_type, match_threshold)
      relevancy_counts = {}
      unsorted_results = []
      search_models.each do |model|
        model_results = base_results.where(:model_constant => model)
        unless model_results.empty?
          relevancy_counts[model] = {}
          model_results.each do |result|
            id_array = result.retrieve_id_array
            id_array.each do |object_id|
              if relevancy_counts[model][object_id].nil?
                relevancy_counts[model][object_id] = 1
              else
                relevancy_counts[model][object_id] = (relevancy_counts[model][object_id] + 1)
              end
            end
          end
          if match_type == :all
            relevancy_counts[model].delete_if do |object_id, count|
              count < match_threshold
            end
          end
        end
        unsorted_results << relevancy_counts[model].to_a.map{|result| result << model}
      end
      return unsorted_results
    end

    def self.sort_by_relevance(base_results, search_object, match_threshold)
      unsorted_results = ARSearch.get_object_counts(base_results, search_object.search_models, search_object.options(:match), match_threshold).flatten!(1) || []
      unless unsorted_results.empty?
        sorted_results = unsorted_results.sort_by {|x| [x[1], x[0]]}
        if search_object.options(:sort_direction) == :desc
          sorted_results = sorted_results.reverse
        end
        return sorted_results.collect {|result| result[2].constantize.find(result[0])}
      else
        return []
      end
    end

    def self.sort_by_field(base_results, search_object, match_threshold)
      unsorted_results = ARSearch.get_object_counts(base_results, search_object.search_models, search_object.options(:match), match_threshold).flatten!(1) || []
      unless unsorted_results.empty?
        unsorted_objects = unsorted_results.collect {|result| result[2].constantize.find(result[0])}
        sort_method = search_object.options(:sort_method)
        case sort_method.class.to_s
        when 'Symbol'
          sorted_results = unsorted_objects.sort_by {|object| object[sort_method]}
        when 'Proc'
          sorted_results = unsorted_objects.sort_by {|object| sort_method.call(object)}
        else
          sorted_results = unsorted_objects
        end
        if search_object.options(:sort_direction) == :desc
          sorted_results = sorted_results.reverse
        end
        return sorted_results 
      else
        return []
      end
    end
  end
end
