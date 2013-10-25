Gem::Specification.new do |spec|
	spec.name           = "ar-indexer"
	spec.version        = "0.0.1"
	spec.date           = "2013-10-25"
	spec.summary        = "Allows for reverse indexing selected ActiveRecord models. Handles searching and return of objects"
	spec.description    = ""
	spec.authors        = ["Josh Stump"]
	spec.email          = "joshua.t.stump@gmail.com"
	spec.homepage       = "https://github.com/jstump/ar-indexer"
	spec.require_paths  = ["lib"]
	spec.files          = [
													"./lib/ar-indexer.rb"
	]
	spec.license        = "GPL-2"
	
	spec.add_dependency('activerecord')
end
