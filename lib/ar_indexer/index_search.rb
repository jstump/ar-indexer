module ARIndexer
  class IndexSearch
    def initialize(models, opts)
      @models = {}
      models.each do |model|
        @models[model.to_s.split('::').last] = model
      end

      @options = {
        :fields => [],
        :match => :any,
        :sort => :relevance,
        :no_results_message => 'No results were returned for the given search term.'
      }
      @options.merge!(opts)
    end

    def expand_search_string(value)
      # 
    end

    def search(value)
      # 
    end

    def no_results_message
      # 
    end
  end
end
