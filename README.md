#ARIndexer#

ARIndexer provides basic indexing and text search for ActiveRecord models. You choose which fields to index per model, and the index is automatically generated/updated on create/edit.

##Installation##

Add ARIndexer to your Gemfile
    
    gem 'ar-indexer'

Write a migration to add a reverse_indices table to the database (Rails migration generator coming soon)

    class CreateReverseIndices < ActiveRecord::Migration
      def change
        create_table :reverse_indices do |t|
          t.string :model_name
          t.string :word
          t.text :id_list
        end
        add_index :reverse_indices, [:model_name, :word], :unique => true
      end
    end

Run `rake db:migrate`

##Usage##

###Indexing###

Have an ActiveRecord model? Want to index some text for searching? Just add the `has_reverse_index` function to your model. Call the function with no parameters and ARIndexer will index all string and text fields. You can pass an optional array of field names (as symbols), and ARIndexer will index only these fields.

    class Post < ActiveRecord::Base
      has_reverse_index
    end

    class Article < ActiveRecord::Base
      has_reverse_index([:title, :content])
    end

At this point, ARIndexer will build and maintain a reverse index for each record under these models.

###Searching###

ARIndexer also provides a simple search class for finding records by text search. To initialize an instance of this class, just pass it the ActiveRecord model it needs to search.

    foo = IndexSearch.new(Article)

You can also pass an options hash (which currently has a whole 1 option, `:no_results_message`)

    foo = IndexSearch.new(Article, :no_results_message => "Hey man, there's nothing there.")

And now you're ready to search against the index that's been built.

    foo.run_search('some search string')

`run_search` will return an array of ActiveRecord objects ordered by the number of matched terms within your search string. If no objects matched your search string, an emtpy array is returned. If no results are returned, you can request the `:no_results_message`

    results = foo.run_search('some search string')
    unless results.empty?
      # Do stuff with your results
    else
      puts foo.no_results_message    #=> Hey man, there's nothing there.
    end
