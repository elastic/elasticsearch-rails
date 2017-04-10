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
