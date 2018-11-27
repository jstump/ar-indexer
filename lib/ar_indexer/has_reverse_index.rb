module ARIndexer
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_reverse_index(**indexing_opts)
        if indexing_opts.nil?
          indexing_opts = {}
        end

        fields = indexing_opts[:fields] || []

        fields.each do |field_name|
          unless self.columns_hash.keys.include?(field_name.to_s)
            unless ['string', 'text'].include?(self.columns_hash[field_name.to_s].type.to_s)
              raise TypeError, 'Model properties provided to has_reverse_index() must be of field type string or text.'
            end
          end
        end

        associations = indexing_opts[:associations] || {}

        associations.each do |association_name, access_function|
          unless access_function.is_a?(Proc)
            raise TypeError, 'Model associations must have a Proc provided in order to reach the appropriate value.'
          end
        end

        send :include, InstanceMethods

        class_attribute :ari_configuration

        self.ari_configuration = {
          fields: [],
          associations: {},
          index_on_create: [],
          index_on_update: []
        }.merge(indexing_opts)

        after_create :ar_indexer_on_create
        after_update :ar_indexer_on_update
        before_destroy :ar_indexer_on_destroy
      end

      module_function :has_reverse_index

      module InstanceMethods
        def index_object(cleanup = false)
          values_to_index = ar_indexer_get_indexable_values

          values_to_index.each do |field_name, value|
            Indexer.index_string(self.class.to_s.split('::').last, self.id, field_name, value, cleanup)
          end
        end

        def index_fields(cleanup = false)
          values_to_index = ar_indexer_get_indexable_values([:fields])

          values_to_index.each do |field_name, value|
            Indexer.index_string(self.class.to_s.split('::').last, self.id, field_name, value, cleanup)
          end
        end

        def index_associations(cleanup = false)
          values_to_index = ar_indexer_get_indexable_values([:associations])

          values_to_index.each do |field_name, value|
            Indexer.index_string(self.class.to_s.split('::').last, self.id, field_name, value, cleanup)
          end
        end

        private

        def ar_indexer_get_indexable_values(index = [:fields, :associations])
          values_to_index = {}

          if index.include?(:fields)
            ari_fields = self.class.ari_configuration[:fields].map{|f| f.to_s}
            indexed_columns = self.class.ari_configuration[:fields].empty? ? self.class.column_names : (self.class.column_names & ari_fields)
            values_to_index.merge!(ar_indexer_gather_column_values(indexed_columns))
          end

          if index.include?(:associations) and !self.class.ari_configuration[:associations].empty?
            self.class.ari_configuration[:associations].each do |association_name, access_function|
              value = access_function.call(self)

              if value.is_a?(String)
                values_to_index[association_name.to_s] = value unless value.empty?
              end
            end
          end

          return values_to_index
        end

        def ar_indexer_gather_column_values(columns)
          column_values = {}

          columns.each do |column|
            value = self.read_attribute(column)

            if value.is_a?(String)
              column_values[column] = value unless value.empty?
            end
          end

          return column_values
        end

        def ar_indexer_on_create
          to_index = self.class.ari_configuration[:index_on_create]

          if to_index == []
            self.index_object(false)
          else
            self.index_fields(false) if to_index.include? :fields
            self.index_associations(false) if to_index.include? :associations
          end
        end

        def ar_indexer_on_update
          to_index = self.class.ari_configuration[:index_on_update]

          if to_index == []
            self.index_object(true)
          else
            self.index_fields(true) if to_index.include? :fields
            self.index_associations(true) if to_index.include? :associations
          end
        end

        def ar_indexer_on_destroy
          Indexer.remove_index_id(self.class.to_s, self.id)
        end
      end
    end
  end
end
