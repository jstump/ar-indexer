module ARIndexer

	class IndexSearch

		def initialize(model_name, opts = {})
			@model_name = model_name.to_s.split('::').last
			@model_class = @model_name.constantize

			@options = {
				:no_results_message => "Your #{@model_name} search returned no results."
			}

			@options.merge!(opts)
		end

		def no_results_message
			return @options[:no_results_message]
		end

		def run_search(search_string)
			search_terms = Indexer.text_to_lexicon(search_string)
			match_counts = {}
			search_terms.each do |st|
				if reverse_index_record = ReverseIndex.where(:model_name => @model_name, :word => st).first
					reverse_index_record.retrieve_id_array.each do |id|
						if match_counts.has_key?(id)
							match_counts[id] = match_counts[id] + 1
						else
							match_counts[id] = 1
						end
					end
				end
			end
			unless match_counts.empty?
				objects_to_return = []
				match_counts.to_a.sort{|x,y| x[1] <=> y[1]}.collect{|x| x[0]}.reverse.each do |id|
					objects_to_return << @model_class.find(id)
				end
				return objects_to_return
			else
				return []
			end
		end

	end

end
