# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticsearch/model/version'

Gem::Specification.new do |s|
  s.name          = "elasticsearch-model"
  s.version       = Elasticsearch::Model::VERSION
  s.authors       = ["Karel Minarik"]
  s.email         = ["karel.minarik@elasticsearch.org"]
  s.description   = "ActiveModel/Record integrations for Elasticsearch."
  s.summary       = "ActiveModel/Record integrations for Elasticsearch."
  s.homepage      = "https://github.com/elasticsearch/elasticsearch-rails/"
  s.license       = "Apache 2"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.extra_rdoc_files  = [ "README.md", "LICENSE.txt" ]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.required_ruby_version = ">= 1.9.3"

  s.add_dependency "elasticsearch",       '> 1'
  s.add_dependency "activesupport",       '> 3'
  s.add_dependency "hashie"

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake", "~> 11.1"

  s.add_development_dependency "elasticsearch-extensions"

  s.add_development_dependency "sqlite3" unless defined?(JRUBY_VERSION)
  s.add_development_dependency "activemodel",   "> 3"

  s.add_development_dependency "oj" unless defined?(JRUBY_VERSION)
  s.add_development_dependency "kaminari"
  s.add_development_dependency "will_paginate"

  s.add_development_dependency "minitest"
  s.add_development_dependency "test-unit"
  s.add_development_dependency "shoulda-context"
  s.add_development_dependency "mocha"
  s.add_development_dependency "turn"
  s.add_development_dependency "yard"
  s.add_development_dependency "ruby-prof" unless defined?(JRUBY_VERSION)
  s.add_development_dependency "pry"

  s.add_development_dependency "simplecov"
  s.add_development_dependency "cane"
  s.add_development_dependency "require-prof"
end
