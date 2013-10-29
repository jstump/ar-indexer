module ARIndexer

	module Model

		def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

    	def has_reverse_index()
    		# 
    	end

    end

  end

end
