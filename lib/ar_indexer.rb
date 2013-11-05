# Requires for gem dependencies
require 'active_record'
require 'active_support'
require 'active_support/inflector'
require 'htmlentities'
require 'fast-stemmer'
# Gem files
require 'ar_indexer/reverse_index'
require 'ar_indexer/has_reverse_index'
require 'ar_indexer/stopwords'
require 'ar_indexer/indexer'
require 'ar_indexer/index_search'

module ARIndexer

	VERSION = "0.1.2"

end

include ARIndexer
ActiveSupport.on_load(:active_record) do
  include ARIndexer::Model
end
