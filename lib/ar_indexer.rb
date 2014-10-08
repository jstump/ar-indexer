# Require runtime dependencies
require 'active_record'
require 'active_support'
require 'active_support/inflector'
require 'htmlentities'
require 'fast-stemmer'

# Require gem files
require 'ar_indexer/reverse_index'
require 'ar_indexer/has_reverse_index'
require 'ar_indexer/indexer'
require 'ar_indexer/index_search'

# Main gem module
module ARIndexer
  # Gem version storage
  module Version
    MAJOR = '0'
    MINOR = '2'
    BUILD = '2'

    STRING = "#{MAJOR}.#{MINOR}.#{BUILD}"
  end
end

include ARIndexer
ActiveSupport.on_load(:active_record) do
  include ARIndexer::Model
end
