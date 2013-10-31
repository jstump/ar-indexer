module ARIndexer

	module Indexer

		STOPWORDS = ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "can't", "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", "your", "yours", "yourself", "yourselves"]

		def self.text_to_lexicon(text)
			# Replace any HTML tag with a space
			text.gsub!(/<[^>]+>/, ' ')
			# Decode HTML entities
			coder = HTMLEntities.new
			text = coder.decode(text)
			# Perform the initial split on spaces
			lexicon = text.split(/\s+/)
			# Drop any words that include no letters or numbers
			# Also drop URLs and email addresses
			lexicon.delete_if {|word| word.match(/(^[^\w\d]+$)|(^http(s){0,1}:\/\/.+$)|(^[a-zA-Z0-9\._\-]+@([a-zA-Z0-9\-_]+\.)+[a-zA-Z]{1,4}$)/)}
			# Clean up each array entry
			lexicon.each do |word|
				# Shift everything to lower case
				word.downcase!
				# Remove beginning and ending punctuation
				word.gsub!(/(^[^a-z0-9]+|[^a-z0-9]+$)/, '')
			end
			# Remove stopwords and take only the unique entries
			lexicon = (lexicon - STOPWORDS).uniq
			# Make a pass at obtaining additional words for matching
			lexicon.each do |word|
				lexicon = lexicon.inject([word.gsub(/'/, ''), word.gsub(/'.+$/, '')], :<<) if word.match(/'/)
				if word.match(/[\-_\|\/]/)
					lexicon = lexicon.inject([word.split(/[\-_\|\/]/)], :<<)
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
			lexicon = (lexicon - STOPWORDS).uniq
			# Drop any entries shorter than 2 characters
			lexicon.delete_if {|word| word.length < 2}
			# Return the lexicon array
			return lexicon
		end

		def self.build_reverse_index(values_to_index)
			forward_index = []
			values_to_index.each do |v|
				forward_index << self.text_to_lexicon(v) if ![nil, ''].include? v
			end
			forward_index = forward_index.flatten.uniq.sort
			return forward_index
		end

	end

end
