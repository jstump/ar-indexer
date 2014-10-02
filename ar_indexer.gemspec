Gem::Specification.new do |spec|
  # Basic Gem Description
  spec.name          = "ar_indexer"
  spec.version       = "0.2.0"
  spec.date          = "2014-10-01"
  spec.summary       = "Allows for reverse indexing selected ActiveRecord models. Handles searching and return of objects"
  spec.description   = spec.summary
  spec.authors       = ["Josh MacLachlan"]
  spec.email         = "josh.t.maclachlan@gmail.com"
  spec.homepage      = "https://github.com/jtmaclachlan/ar_indexer"
  spec.require_paths = ["lib"]
  spec.files         = `git ls-files`.split("\n")
  spec.license       = "GPL-2"
  
  # Runtime Dependencies
  spec.add_dependency('activerecord', '>= 3.0.0')
  spec.add_dependency('activesupport', '>= 3.0.0')
  spec.add_dependency('htmlentities')
  spec.add_dependency('fast-stemmer')

  # Post-Install Message
end
