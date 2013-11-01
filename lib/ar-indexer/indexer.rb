module ARIndexer

	module Indexer

		def self.text_to_lexicon(text)
			# Replace any HTML tag with a space
			text.gsub!(/<[^>]+>/, ' ')
			# Decode HTML entities
			coder = HTMLEntities.new
			text = coder.decode(text)
			# Perform the initial split on spaces
			lexicon = text.split(/\s+/)
			# Drop any words that include no letters or numbers
			lexicon.delete_if {|word| word.match(/^[^\w\d]+$/)}
			# Clean up each array entry
			lexicon.each do |word|
				# Shift everything to lower case
				word.downcase!
				# Remove beginning and ending punctuation
				word.gsub!(/(^[^a-z0-9]+|[^a-z0-9]+$)/, '')
			end
			# Remove stopwords and take only the unique entries
			lexicon = (lexicon - Stopwords::STOPWORDS).uniq
			# Make a pass at obtaining additional words for matching
			lexicon.each do |word|
				lexicon = lexicon.inject([word.gsub(/'/, ''), word.gsub(/'.+$/, '')], :<<) if word.match(/'/)
				if word.match(/[\-_\|\/]/)
					lexicon = lexicon.inject([word.split(/[\-_\|\/@\.]/)], :<<)
				end
				stem = Stemmer.stem_word(word)
				if stem != word && !stem.match(/[^a-z0-9]$/)
					lexicon = lexicon.inject([stem], :<<)
				end
				plural = word.pluralize
				if plural != word
					lexicon = lexicon.inject([plural], :<<)
				end
			end
			# Flatten any new arrays gained by splitting words
			lexicon = lexicon.flatten
			# Remove stopwords and take only the unique entries
			lexicon = (lexicon - Stopwords::STOPWORDS).uniq
			# Drop any entries shorter than 2 characters
			lexicon.delete_if {|word| word.length < 2}
			# Return the lexicon array
			return lexicon
		end

		def self.build_forward_index(values_to_index)
			forward_index = []
			# Run text_to_lexicon for each indexed field
			values_to_index.each do |v|
				forward_index << self.text_to_lexicon(v) if ![nil, ''].include? v
			end
			# Return the lexicon flattened, uniquified, and in alphabetical order
			forward_index = forward_index.flatten.uniq.sort
			return forward_index
		end

		def self.clean_reverse_index(model_name, record_id, forward_index)
			reverse_index_records = ReverseIndex.where(:model_name => model_name)
			reverse_index_records.each do |rir|
				if rir.id_list.match(/,{0,1}#{record_id},{0,1}/)
					if !forward_index.include? rir.word
						id_array = rir.retrieve_id_array
						id_array.delete(record_id.to_i)
						if id_array.empty?
							rir.destroy
						else
							new_id_list = id_array.join(',')
							rir.update(:id_list => new_id_list)
						end
					end
				end
			end
		end

		def self.build_reverse_index(model_name, record_id, values_to_index, cleaning_required = false)
			forward_index = self.build_forward_index(values_to_index)
			forward_index.each do |word|
				if reverse_index_record = ReverseIndex.where(:model_name => model_name, :word => word).first
					id_array = reverse_index_record.retrieve_id_array
					if !id_array.include? record_id
						new_id_list = (id_array << record_id).join(',')
						reverse_index_record.update(:id_list => new_id_list)
					end
				else
					ReverseIndex.create(:model_name => model_name, :word => word, :id_list => record_id)
				end
			end
			self.clean_reverse_index(model_name, record_id, forward_index) if cleaning_required
		end

		def self.remove_from_reverse_index(model_name, record_id)
			reverse_index_records = ReverseIndex.where(:model_name => model_name)
			reverse_index_records.each do |rir|
				id_array = rir.retrieve_id_array
				if id_array.include? record_id.to_i
					id_array.delete(record_id.to_i)
					if id_array.empty?
						rir.destroy
					else
						rir.update(:id_list => id_array.join(','))
					end
				end
			end
		end

	end

end
