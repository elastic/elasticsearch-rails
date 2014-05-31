# Elasticsearch

This repository contains various Ruby and Rails integrations for [Elasticsearch](http://elasticsearch.org):

* ActiveModel integration with adapters for ActiveRecord and Mongoid
* _Repository Pattern_ based persistence layer for Ruby objects
* Enumerable-based wrapper for search results
* ActiveRecord::Relation-based wrapper for returning search results as records
* Convenience model methods such as `search`, `mapping`, `import`, etc
* Rake tasks for importing the data
* Support for Kaminari and WillPaginate pagination
* Integration with Rails' instrumentation framework
* Templates for generating example Rails application

Elasticsearch client and Ruby API is provided by the
**[elasticsearch-ruby](https://github.com/elasticsearch/elasticsearch-ruby)** project.

## Installation

The libraries are compatible with Ruby 1.9.3 and higher.

Install the `elasticsearch-model` and/or `elasticsearch-rails` package from
[Rubygems](https://rubygems.org/gems/elasticsearch):

    gem install elasticsearch-model elasticsearch-rails

To use an unreleased version, either add it to your `Gemfile` for [Bundler](http://gembundler.com):

    gem 'elasticsearch-model', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'
    gem 'elasticsearch-rails', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'

or install it from a source code checkout:

    git clone https://github.com/elasticsearch/elasticsearch-rails.git
    cd elasticsearch-model
    bundle install
    rake install
    cd elasticsearch-rails
    bundle install
    rake install

## Usage

This project is split into three separate gems:

* [**`elasticsearch-model`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-model),
  which contains search integration for Ruby/Rails models such as ActiveRecord::Base and Mongoid,

* [**`elasticsearch-persistence`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-persistence),
  which provides standalone persistence layer for Ruby/Rails objects and models

* [**`elasticsearch-rails`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-rails),
  which contains various features for Ruby on Rails applications

Example of a basic integration into an ActiveRecord-based model:

```ruby
require 'elasticsearch/model'

class Article < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
end

Article.import

@articles = Article.search('foobar').records
```

Example of using Elasticsearch as a repository for a Ruby model:

```ruby
require 'virtus'
class Article
  include Virtus.model
  attribute :title, String
end

require 'elasticsearch/persistence'
repository = Elasticsearch::Persistence::Repository.new

repository.save Article.new(title: 'Test')
# POST http://localhost:9200/repository/article [status:201, request:0.760s, query:n/a]
# => {"_index"=>"repository", "_type"=>"article", "_id"=>"Ak75E0U9Q96T5Y999_39NA", ...}
```

You can generate a fully working Ruby on Rails application with a single command:

```bash
rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/01-basic.rb
```

**Please refer to each library documentation for detailed information and examples.**

### Model

* [[README]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-model/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-model/)
* [[Test Suite]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-model/test)

### Persistence

* [[README]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-persistence/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-persistence/)
* [[Test Suite]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-persistence/test)

### Rails

* [[README]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-rails/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-rails)
* [[Test Suite]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-rails/test)

## License

This software is licensed under the Apache 2 license, quoted below.

    Copyright (c) 2014 Elasticsearch <http://www.elasticsearch.org>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
