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

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
