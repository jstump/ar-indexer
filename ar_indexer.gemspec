Gem::Specification.new do |spec|
  spec.name           = "ar_indexer"
  spec.version        = "0.1.4"
  spec.date           = "2014-02-18"
  spec.summary        = "Allows for reverse indexing selected ActiveRecord models. Handles searching and return of objects"
  spec.description    = spec.summary
  spec.authors        = ["Josh Stump"]
  spec.email          = "joshua.t.stump@gmail.com"
  spec.homepage       = "https://github.com/jstump/ar_indexer"
  spec.require_paths  = ["lib"]
  spec.files          = `git ls-files`.split("\n")
  spec.license        = "GPL-2"
  
  spec.add_dependency('activerecord')
  spec.add_dependency('activesupport')
  spec.add_dependency('htmlentities')
  spec.add_dependency('fast-stemmer')
end
