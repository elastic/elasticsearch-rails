## 2.0.0

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

### Persistence

* Updated dependencies in gemspec

## 0.1.9

The last version for the old versioning scheme -- please see the Git commit log
at https://github.com/elastic/elasticsearch-rails/commits/v0.1.9
