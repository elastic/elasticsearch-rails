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
