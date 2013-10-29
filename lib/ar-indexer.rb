require 'ar-indexer/has-reverse-index'

module ARIndexer

	VERSION = "0.0.1"

end

ActiveSupport.on_load(:active_record) do
  include ARIndexer::Model
end
