# Requires for gem dependencies
require 'active_record'
require 'active_support'
require 'active_support/inflector'
require 'htmlentities'
require 'fast-stemmer'
# Gem files
require 'ar-indexer/reverse-index'
require 'ar-indexer/has-reverse-index'
require 'ar-indexer/stopwords'
require 'ar-indexer/indexer'

module ARIndexer

	VERSION = "0.0.1"

end

include ARIndexer
ActiveSupport.on_load(:active_record) do
  include ARIndexer::Model
end
