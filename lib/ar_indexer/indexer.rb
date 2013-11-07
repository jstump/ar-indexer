module ARIndexer

	# Contains functions for creating a forward index from text, then converting it to a reverse index

	module Indexer

		# Turns a string into lexicon array, including basic root words and plurals
		# 
		# ==== Parameters
		# 
		# text: the string to be converted
		# 
		# ==== Returns
		# 
		# array of strings

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

		# Takes an array of strings to be indexed, and calls text_to_lexicon on each.
		# Returns the combined array flattened, uniquified, and sorted in alphabetical order
		# 
		# ==== Parameters
		# 
		# values_to_index: array of string values to index
		# 
		# ==== Returns
		# 
		# array of strings

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

		# For a given model name and object id, compares the list of words with the forward index of the text.
		# If a word exists in the reverse index but not the forward index, removes the object id from the reverse index.
		# If the id array is empty, removes the reverse index record
		# 
		# ==== Parameters
		# 
		# * model_name: string version of the model name to clean records for
		# * record_id: object id to search for in the reverse index
		# * forward_index: the array of words to check against

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

		# Takes an array of values to index, runs it through build_forward_index(), then builds the reverse index
		# from the returned values
		# 
		# ==== Parameters
		# 
		# * model_name: the string version of the model name
		# * record_id: the id of the object being indexed
		# * values_to_index: array of string objects to use in building the reverse index
		# * cleaning_required: boolean flag, whether or not to run clean_reverse_index()

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

		# Removes an object id from the reverse index for a specified model.
		# If the id array is empty after removing the record id, destroys the reverse index record
		# 
		# ==== Parameters
		# 
		# model_name: string version of the model name to remove records for
		# record_id: object id to remove records for

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
