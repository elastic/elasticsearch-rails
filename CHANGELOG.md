## 7.2.1

* The default git branch `master` has been renamed to `main`
* Adds compatibility with Ruby 3 [Pull Request](https://github.com/elastic/elasticsearch-rails/pull/992)

## 7.2.0

* Updates specs and dependency to use with `elasticsearch` v7.14.0.
* Update README, remove Virtus (unmaintained)
* Updates `Bundler.with_clean_dev` (deprecated) to `with_unbundled_env` [commit](https://github.com/elastic/elasticsearch-rails/commit/e4545e4fe2a1ce80009206c831d5740360bad6c2)
* Deal with `nil` document types in Multimodel [commit](https://github.com/elastic/elasticsearch-rails/commit/cd9c309b78de443d2e37760998418616ba34276d)
* Update dependency to explicitly support version 7 [commit](https://github.com/elastic/elasticsearch-rails/commit/65942e3da9cabad2f6965e69c8ef6a0994da9408)
* Stop emitting FATAL log when checking existence of indices [commit](https://github.com/elastic/elasticsearch-rails/commit/5db9207ca398c5d77f671109360ca7f63e3f2112)
* Remove unnecessary exception test on index checking [commit](https://github.com/elastic/elasticsearch-rails/commit/ce57cc17e304b0a4af123c1599f37fb892a5d93a)
* Removes dependency on extensions [commit](https://github.com/elastic/elasticsearch-rails/commit/ed070b8329ca48b4cb12b513ac81ed78c88acc61)
* Fixes basic template elasticsearch dependency [commit](https://github.com/elastic/elasticsearch-rails/commit/a4ec07b2d097545ca41c13686c9cbfc9eab9e639)

### ActiveModel

* Fixes indexing to use right logger in client
* Updates ES client spec for client 7.14.0
* Updates transport references

## 7.1.1

* Fix: Ruby 2.7 deprecation warning on `find_in_batches`
* Updates README for generating app with template. Related: #938

### ActiveModel

* Do not override existing methods (#936)

## 7.1.0

* Tested with elasticsearch Ruby client version 7.6.0
* Updates rake version
* Adds pipeline to bulk params [commit](https://github.com/elastic/elasticsearch-rails/commit/63c24c9fe48a74d00c65145cc55c32f4c6907448)

## 7.0.0

* Update test tasks and travis (#840)
* `respond_to_missing?` to silence Ruby 2.4 warnings (#838)
* Update README.md to link to migration blog post (#857)
* Add license headers, LICENSE and NOTICE files (#861)
* Only execute update if document attributes is not empty (#862)
* Remove bundler version requirement in gemspec files
* 7.0 support (#875)

### ActiveModel

* Fix import when preprocess returns empty collection (#720)
* Add test for not importing when ActiveRecord query is empty
* with 0
* Port basic response tests to rspec (#833)
* Add newlines at the end of files that are missing it
* Port adapter tests to rspec (#834)
* Ensure that specified ActiveRecord order is not overwritten by Elasticsearch search results order (#835)
* Port remainder of Elasticsearch::Model unit tests to rspec (#836)
* Port all integration tests to rspec (#837)
* Avoid executing search twice; Reuse response in Response#raw_response (#850)
* Update example to account for deprecation of _suggest endpoint in favor of _search
* Handle total hits as an object in search response
* Use logger to log index not found message (#868)
* Test against Rails 6.0.rc1

### Persistence

* Ensure that arguments are passed to super (#853)
* Index name option is handled by super, no need to pass options expicitly
* Handle total hits as an object in search response

### Ruby on Rails

* Convert tests to rspec (#842)
* Fix seeds file to stop using outdated YAML method (#843)
* Fixed 03-expert.rb set tracer only in dev env (#621)

## 6.0.0

* Update to test against Elasticsearch 6.4
* Fix sort order on ActiveRecord >= 5. re issue #546 (#831)

### ActiveModel

* Inherit from HashWrapper for disabling warnings
* Fix import method to pass index name on refresh (#692)
* Use default scope on ActiveRecord model when importing (#827)
* Support scope, query and preprocess importing options in Mongoid Adapter in 6.x (#829)
* Address performance of HashWrapper in Response objects (#825)

### Persistence

* Address performance of HashWrapper in Response objects (#825)
* Minor refactor in Repository::Search
* Remove example music app that demonstrates the AR pattern
* Update Sinatra app
* Update README
* Change document type references to _doc

## 6.0.0.pre

* Added the "Compatibility" chapter to the READMEs
* Updated the Bundler instructions and Github URLs in the READMEs
* Updated the version on the `master` branch to `6.0.0.alpha1`
* Update versions to 6.0.0.beta
* minor: Fix spacing
* Update various gemspecs to conditionally depend on gems incompatible with JRuby (#810)
* Update versions
* Use local as source for gem dependencies when possible
* Only require 'oj' gem if not using JRuby
* Update versions to .pre

### ActiveModel

* Added an example with a custom "pattern" analyzer
* Added a "trigram" custom analyzer to the example
* Fix README typo (s/situation/situations)
* Fix reference to @ids in example and README
* Add Callbacks to the example datamapper adapter
* Fix `Asynchronous Callbacks` example
* Fixed a typo in the README
* Improved the custom analyzer example
* Removed left-overs from previous implementation in the "completion suggester" example
* Updated the `changes` method name in `Indexing` to `changes_to_save` for compatibility with Rails 5.1
* Fixed the handling of changed attributes in `Indexing` to work with older Rails versions
* Update child-parent integration test to use single index type for ES 6.3 (#805)
* Use default doc type: _doc (#814)
* Avoid making an update when no attributes are changed (#762)

### Persistence

* Updated the failing integration tests for Elasticsearch 5.x
* Updated the dependency for "elasticsearch" and "elasticsearch-model" to `5.x`
* Documentation for Model should include Model and not Repository
* Depend on version >= 6 of elasticsearch gems
* Undo last commit; depend on version 5 of elasticsearch gems
* Reduce repeated string instantiation (#813)
* Make default doc type '_doc' in preparation for deprecation of mapping types (#816)
* Remove Elasticsearch::Persistence::Model (ActiveRecord persistence pattern) (#812)
* Deprecate _all field in ES 6.x (#820)
* Remove development dependency on virtus, include explicitly in Gemfile for integration test
* Refactor Repository as mixin (#824)
* Add missing Repository::Response::Results spec
* Update README for Repository mixin refactor
* Minor typo in README
* Add #inspect method for Repository
* Update references to Elasticsearch::Client

### Ruby on Rails

* Fixed typo in README
* Fix typo in rake import task
* Updated the templates for example Rails applications
* Add 'oj' back as a development dependency in gemspec

## 6.0.0.alpha1

* Updated the Rake dependency to 11.1
* Reduced verbosity of `rake test:unit` and `rake test:integration`
* Removed the "CI Reporter" integration from test Rake tasks
* Added the "Compatibility" chapter to the READMEs
* Updated the Bundler instructions and Github URLs in the READMEs

### ActiveModel

* Fixed a problem where `Hashie::Mash#min` and `#max` returned unexpected values
* Added information about `elasticsearch-dsl` to the README
* Added support for inherited index names and doc types
* Added a `Elasticsearch::Model.settings` method
* Changed the naming inheritance logic to use `Elasticsearch::Model.settings`
* Added information about the `settings` method and the `inheritance_enabled` setting into the README
* Disable "verbose" and "warnings" in integration tests
* Added code for establishing ActiveRecord connections to test classes
* Reorganized the class definitions in the integration tests
* Moved `require` within unit test to the top of the file
* Added ActiveRecord 5 support to integration test configuration
* Fixed records sorting with ActiveRecord 5.x
* Added, that `add_index` for ActiveRecord models is only called when it doesn't exist already
* Use `records.__send__ :load` instead of `records.load` in the ActiveRecord adapter
* Call `Kaminari::Hooks.init` only when available
* Fixed the deprecation messages for `raise_in_transactional_callbacks`
* Fixed the deprecation messages for `timestamps` in migrations in integration tests
* Fixed the naming for the indexing integration tests
* Fixed the failing integration tests for ActiveRecord associations
* Fixed integration tests for ActiveRecord pagination
* Added the `rake bundle:install` Rake task to install dependencies for all gemfiles
* Run unit tests against all Gemfiles
* Updated dependencies in gemspec
* Relaxed the dependency on the "elasticsearch" gem
* Fixed the completion example for ActiveRecord for Elasticsearch 5
* Added an example with Edge NGram mapping for auto-completion
* Expanded the example for indexing and searching ActiveRecord associations
* Added an example for source filtering to the ActiveRecord associations example
* Fixed a typo in the README
* Changed the default mapping type to `text`
* Added a `HashWrapper` class to wrap Hash structures instead of raw `Hashie::Mash`
* Call `Hashie.disable_warnings` method in Response wrappers
* Added, that `HashWrapper`, a sub-class of `Hashie::Mash` is used
* Updated the configuration for required routing in the integration test
* Fixed incorrect name for the parent/child integration test
* Fixed incorrect mapping configuration in the integration tests
* Allow passing the index settings and mappings as arguments to `create_index!`
* Added instructions about creating the index into the README
* Updated the "completion suggester" example

### Persistence

* Updated dependencies in gemspec
* Updated dependencies in gemspec
* Relaxed the dependency on the "elasticsearch" gem
* Use `text` instead of `string` for the <String> data types
* Changed the default mapping type to `text`
* Removed the `search_type=scan` in the `find_in_batches` method
* Updated the `count` method in the "repository" module
* Updated the "update by script" integration test for Elasticsearch 5
* Added, that `HashWrapper`, a sub-class of `Hashie::Mash` is used
* Updated the "Notes" example application for Elasticsearch 5.x
* Updated the "Music" example application for Elasticsearch 5.x
* Updated the URLs in the "Music" application template
* Updated the Git URLs in the "Notes" example application

### Ruby on Rails

* Updated the application templates to support Rails 5 & Elasticsearch 5
* Updated the `03-expert` application template to work with Rails 5
* Updated the application templates to work with README.md instead of README.rdoc
* Updated the installation process in the "01-basic" application template
* Fixed typo in README
* Fix typo in rake import task

## 0.1.9

The last version for the old versioning scheme -- please see the Git commit log
at https://github.com/elastic/elasticsearch-rails/commits/v0.1.9
