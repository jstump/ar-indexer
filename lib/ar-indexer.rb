require 'active_record'
require 'active_support'
require 'ar-indexer/has-reverse-index'
require 'ar-indexer/indexer'

module ARIndexer

	VERSION = "0.0.1"

end

include ARIndexer
ActiveSupport.on_load(:active_record) do
  include ARIndexer::Model
end
