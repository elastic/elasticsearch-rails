## 0.1.9

* Added a `suggest` method to wrap the suggestions in response
* Added the `:includes` option to Adapter::ActiveRecord::Records for eagerly loading associated models
* Delegated `max_pages` method properly for Kaminari's `next_page`
* Fixed `#dup` behaviour for Elasticsearch::Model
* Fixed typos in the README and examples

## 0.1.8

* Added "default per page" methods for pagination with multi model searches
* Added a convenience accessor for the `aggregations` part of response
* Added a full example with mapping for the completion suggester
* Added an integration test for paginating multiple models
* Added proper support for the new "multi_fields" in the mapping DSL
* Added the `no_timeout` option for `__find_in_batches` in the Mongoid adapter
* Added, that index settings can be loaded from any object that responds to `:read`
* Added, that index settings/mappings can be loaded from a YAML or JSON file
* Added, that String pagination parameters are converted to numbers
* Added, that empty block is not required for setting mapping options
* Added, that on MyModel#import, an exception is raised if the index does not exists
* Changed the Elasticsearch port in the Mongoid example to 9200
* Cleaned up the tests for multiple fields/properties in mapping DSL
* Fixed a bug where continuous `#save` calls emptied the `@__changed_attributes` variable
* Fixed a buggy test introduced in #335
* Fixed incorrect deserialization of records in the Multiple adapter
* Fixed incorrect examples and documentation
* Fixed unreliable order of returned results/records in the integration test for the multiple adapter
* Fixed, that `param_name` is used when paginating with WillPaginate
* Fixed the problem where `document_type` configuration was not propagated to mapping [6 months ago by Miguel Ferna
* Refactored the code in `__find_in_batches` to use Enumerable#each_slice
* Refactored the string queries in multiple_models_test.rb to avoid quote escaping

## 0.1.7

* Improved examples and instructions in README and code annotations
* Prevented index methods to swallow all exceptions
* Added the `:validate` option to the `save` method for models
* Added support for searching across multiple models (elastic/elasticsearch-rails#345),
  including documentation, examples and tests

## 0.1.6

* Improved documentation
* Added dynamic getter/setter (block/proc) for `MyModel.index_name`
* Added the `update_document_attributes` method
* Added, that records to import can be limited by the `query` option

## 0.1.5

* Improved documentation
* Fixes and improvements to the "will_paginate" integration
* Added a `:preprocess` option to the `import` method
* Changed, that attributes are fetched from `as_indexed_json` in the `update_document` method
* Added an option to the import method to return an array of error messages instead of just count
* Fixed many problems with dependency hell
* Fixed tests so they run on Ruby 2.2

## 0.1.2

* Properly delegate existence methods like `result.foo?` to `result._source.foo`
* Exception is raised when `type` is not passed to Mappings#new
* Allow passing an ActiveRecord scope to the `import` method
* Added, that `each_with_hit` and `map_with_hit` in `Elasticsearch::Model::Response::Records` call `to_a`
* Added support for [`will_paginate`](https://github.com/mislav/will_paginate) pagination library
* Added the ability to transform models during indexing
* Added explicit `type` and `id` methods to Response::Result, aliasing `_type` and `_id`

## 0.1.1

* Improved documentation and tests
* Fixed Kaminari implementation bugs and inconsistencies

## 0.1.0 (Initial Version)
