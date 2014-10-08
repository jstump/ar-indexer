#ARIndexer#

[![Gem Version](https://badge.fury.io/rb/ar_indexer.svg)](http://badge.fury.io/rb/ar_indexer)

ARIndexer provides basic indexing and text search for ActiveRecord models. You choose which fields to index per model, and the index is automatically generated/updated on create/edit.

##Installation##

Add ARIndexer to your Gemfile
    
    gem 'ar_indexer'

Write a migration to add a reverse_indices table to the database (Rails migration generator coming soon)

    class CreateReverseIndices < ActiveRecord::Migration
      def change
        create_table :reverse_indices do |t|
          t.string :model_name
          t.string :field_name
          t.string :word
          t.text :id_list
        end
        add_index :reverse_indices, [:model_name, :field_name, :word], :unique => true
      end
    end

Run `rake db:migrate`

##Usage##

###Indexing###

Have an ActiveRecord model? Want to index some text for searching? Just add the `has_reverse_index` function to your model. Call the function with no parameters and ARIndexer will index all string and text fields. You can pass an optional array of field names (as symbols), and ARIndexer will index only these fields. Also, you can pass a hash with association names as keys and a lambda to access the necessary data. Note that the lambda must accept the AR object as its sole argument and must return a string.

    class Post < ActiveRecord::Base
      has_reverse_index
    end

    class Article < ActiveRecord::Base
      has_reverse_index([:title, :content])
    end

    class Article < ActiveRecord::Base
      has_many :article_tags
      has_many :tags, :through => :article_tags
      has_reverse_index(
        [
          :title,
          :content
        ],
        {
          :tags => lambda {|object| object.tags.collect{|tag| tag.name}.join(', ')}
        }
      )

At this point, ARIndexer will build and maintain a reverse index for each record under these models. If you need to reindex the object at any time, the instance methods `reindex_object`, `reindex_fields`, and `reindex_associations` are added to all ActiveRecord objects with `has_reverse_index` declared.

###Searching###

ARIndexer also provides a simple search class for finding records by text search. To initialize an instance of this class, just pass it an array of ActiveRecord models it needs to search.

    foo = IndexSearch.new([Article])
    # Or search multiple models
    # foo = IndexSearch.new([Article, List])

You can also pass an options hash to specify what fields should be searched, how the results should be sorted, a message for displaying if there are no results, etc. The default options hash is displayed below:

    @options = {
      :fields => [],
      # If left as an empty array, will search all fields for the given model
      
      :match => :any,
      # :any will expand your search string and find results that match any keyword
      # :all will only return results that have as many keyword matches as words in the search string
      
      :sort => :relevance,
      # :relevance will sort by number of keyword matches
      # :field allows you to specify a field to sort by
      
      :sort_method => nil,
      # Allows for a lambda by which to access a sortable value.
      # Pass a proc that takes the AR object to access a sortable value
      # Pass the symbol of the field name you want to access to just pull the field value
      
      :sort_direction => :desc,
      # Sort order, default is DESC so that the most relevant results will be returned first
      
      :stopwords => [],
      # An array of words that should not be used in the search.
      # ar_indexer has an internal array of basic stopwords, and these will be added to it
      
      :no_results_message => 'No results were returned for the given search term.'
      # A stored message that can be returned if there are no results returned
    }

    foo = IndexSearch.new([Article],
      {
        :fields => [:title],
        :match => :all,
        :sort => :field,
        :sort_direction => :asc,
        :no_results_message => "Hey man, there's nothing there."
      }
    )

And now you're ready to search against the index that's been built.

    foo.search('some search string')

`foo.search` will return an array of ActiveRecord objects ordered by the number of matched terms within your search string. If no objects matched your search string, an emtpy array is returned. If no results are returned, you can request the `:no_results_message`

    results = foo.run_search('some search string')
    unless results.empty?
      # Do stuff with your results
    else
      puts foo.no_results_message    #=> Hey man, there's nothing there.
    end
