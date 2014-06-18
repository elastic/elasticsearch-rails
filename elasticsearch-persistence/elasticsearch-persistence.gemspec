# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticsearch/persistence/version'

Gem::Specification.new do |s|
  s.name          = "elasticsearch-persistence"
  s.version       = Elasticsearch::Persistence::VERSION
  s.authors       = ["Karel Minarik"]
  s.email         = ["karel.minarik@elasticsearch.org"]
  s.description   = "Persistence layer for Ruby models and Elasticsearch."
  s.summary       = "Persistence layer for Ruby models and Elasticsearch."
  s.homepage      = "https://github.com/elasticsearch/elasticsearch-rails/"
  s.license       = "Apache 2"

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.extra_rdoc_files  = [ "README.md", "LICENSE.txt" ]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.required_ruby_version = ">= 1.9.3"

  s.add_dependency "elasticsearch",       '> 0.4'
  s.add_dependency "elasticsearch-model", '>= 0.1'
  s.add_dependency "activesupport",       '> 3'
  s.add_dependency "activemodel",         '> 3'
  s.add_dependency "hashie"
  s.add_dependency "virtus"

  s.add_development_dependency "bundler", "~> 1.5"
  s.add_development_dependency "rake"

  s.add_development_dependency "oj"

  s.add_development_dependency "rails"

  s.add_development_dependency "elasticsearch-extensions"

  s.add_development_dependency "shoulda-context"
  s.add_development_dependency "mocha"
  s.add_development_dependency "turn"
  s.add_development_dependency "yard"
  s.add_development_dependency "ruby-prof"
  s.add_development_dependency "pry"
  s.add_development_dependency "ci_reporter"

  if defined?(RUBY_VERSION) && RUBY_VERSION > '1.9'
    s.add_development_dependency "simplecov"
    s.add_development_dependency "cane"
  end
end
