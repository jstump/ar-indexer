module ARIndexer
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_reverse_index(fields = [], associations = {})
        fields.each do |field_name|
          unless self.columns_hash.keys.include?(field_name.to_s)
            unless ['string', 'text'].include?(self.columns_hash[field_name.to_s].type.to_s)
              raise TypeError, 'Model properties provided to has_reverse_index() must be of field type string or text.'
            end
          end
        end

        associations.each do |association_name, lambda|
          unless lambda.class == Proc
            raise TypeError, 'Model associations must have a Proc provided in order to reach the appropriate value.'
          end
        end

        send :include, InstanceMethods

        class_attribute :indexed_fields
        class_attribute :indexed_associations
        self.indexed_fields = fields.clone || []
        self.indexed_associations = associations.clone || {}

        after_create :ar_indexer_on_create
        after_update :ar_indexer_on_update
        before_destroy :ar_indexer_on_destroy
      end
      module_function :has_reverse_index

      module InstanceMethods
        private

        def ar_indexer_get_indexable_values
          values_to_index = {}
          
          if self.indexed_fields.empty?
            self.class.columns.each do |column|
              if ['string', 'text'].include? column.type.to_s
                value = self.read_attribute(column.name)
                if value.class == String
                  unless value.empty?
                    values_to_index[column.name] = value
                  end
                end
              end
            end
          else
            self.indexed_fields.each do |field_name|
              value = self[field_name]
              if value.class == String
                unless value.empty?
                  values_to_index[field_name.to_s] = value
                end
              end
            end
          end

          unless self.indexed_associations.empty?
            self.indexed_associations.each do |association_name, lambda|
              value = lambda.call(self)
              if value.class == String
                unless value.empty?
                  values_to_index[association_name.to_s] = value
                end
              end
            end
          end

          return values_to_index
        end

        def ar_indexer_on_create
          ar_indexer_get_indexable_values.each do |field_name, value|
            Indexer.index_string(self.class.to_s.split('::').last, self.id, field_name, value, false)
          end
        end

        def ar_indexer_on_update
          ar_indexer_get_indexable_values.each do |field_name, value|
            Indexer.index_string(self.class.to_s.split('::').last, self.id, field_name, value, true)
          end
        end

        def ar_indexer_on_destroy
          Indexer.remove_index_id(self.class.to_s, self.id)
        end
      end
    end
  end
end
