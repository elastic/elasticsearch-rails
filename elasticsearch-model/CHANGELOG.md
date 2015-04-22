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
