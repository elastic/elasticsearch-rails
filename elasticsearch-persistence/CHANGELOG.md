## 0.1.9

* Added, that raw `_source` is accessible from a model instance

## 0.1.8

* Added `cluster.health wait_for_status: 'yellow'` to Repository integration test
* Fixed tests for the updates to the `update` method for Persistence::Model
* Fixed timestamp tests
* Fixed typos and broken links in documentation, fixed examples
* Fixed, that `MyModel#save` does in fact persist `updated_at` attribute
* Fixed, that `options` have not been passed to gateway in MyModel#update
* Short-circuit the operation and return `false` when the model is not valid
* Fixed the problem where `document_type` configuration was not propagated to mapping


## 0.1.7

* Added an integration test for the `MyModel.all` method
* Improved the "music" example application

## 0.1.6

* Improved documentation
* Refactored the Rails' forms date conversions into a module method
* Changed, that search requests are executed through a `SearchRequest` class

## 0.1.5

* Improved documentation
* Added `@mymodel.id=` setter method

## 0.1.4

* Added the Elasticsearch::Persistence::Model feature

## 0.1.3

* Released the "elasticsearch-persistence" Rubygem

## 0.0.1

* Initial infrastructure for the gem
