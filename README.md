# Elasticsearch

This repository contains various Ruby and Rails integrations for [Elasticsearch](http://elasticsearch.org):

* ActiveModel integration with adapters for ActiveRecord and Mongoid
* _Repository pattern_ based persistence layer for Ruby objects
* _Active Record pattern_ based persistence layer for Ruby models
* Enumerable-based wrapper for search results
* ActiveRecord::Relation-based wrapper for returning search results as records
* Convenience model methods such as `search`, `mapping`, `import`, etc
* Rake tasks for importing the data
* Support for Kaminari and WillPaginate pagination
* Integration with Rails' instrumentation framework
* Templates for generating example Rails application

Elasticsearch client and Ruby API is provided by the
**[elasticsearch-ruby](https://github.com/elasticsearch/elasticsearch-ruby)** project.

## Compatibility

The libraries are compatible with Ruby 1.9.3 and higher.

The version numbers follow the Elasticsearch major versions, and the `master` branch
is compatible with the Elasticsearch `master` branch, therefore, with the next major version.

| Rubygem       |   | Elasticsearch |
|:-------------:|:-:| :-----------: |
| 0.1           | → | 1.x           |
| 2.x           | → | 2.x           |
| 5.x           | → | 5.x           |
| master        | → | master        |

## Installation

Install each library from [Rubygems](https://rubygems.org/gems/elasticsearch):

```ruby
gem install elasticsearch-model
gem install elasticsearch-rails
```

To use an unreleased version, either add it to your `Gemfile` for [Bundler](http://gembundler.com):

```ruby
gem 'elasticsearch-model', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'
gem 'elasticsearch-rails', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'
```

or install it from a source code checkout:

```bash
git clone https://github.com/elasticsearch/elasticsearch-rails.git
cd elasticsearch-model
bundle install
rake install
cd elasticsearch-rails
bundle install
rake install
```

## Usage

This project is split into three separate gems:

* [**`elasticsearch-model`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-model),
  which contains search integration for Ruby/Rails models such as ActiveRecord::Base and Mongoid,

* [**`elasticsearch-persistence`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-persistence),
  which provides a standalone persistence layer for Ruby/Rails objects and models

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

You can generate a simple Ruby on Rails application with a single command
(see the [other available templates](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-rails#rails-application-templates)):

```bash
rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/01-basic.rb
```

Example of using Elasticsearch as a repository for a Ruby domain object:

```ruby
require 'virtus'
class Article
  include Virtus.model
  attribute :title, String
end

require 'elasticsearch/persistence'
repository = Elasticsearch::Persistence::Repository.new

repository.save Article.new(title: 'Test')
# POST http://localhost:9200/repository/article
# => {"_index"=>"repository", "_type"=>"article", "_id"=>"Ak75E0U9Q96T5Y999_39NA", ...}
```

Example of using Elasticsearch as a persistence layer for a Ruby model:

```ruby
require 'elasticsearch/persistence/model'
class Article
  include Elasticsearch::Persistence::Model
  attribute :title, String, mapping: { analyzer: 'snowball' }
end

Article.create title: 'Test'
# POST http://localhost:9200/articles/article
# => #<Article {title: "Test", id: "lUOQ9lhHToWa7oYPxwjqPQ", ...}>
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

## Development

[![Build Status](https://travis-ci.org/elastic/elasticsearch-rails.svg?branch=master)](https://travis-ci.org/elastic/elasticsearch-rails) [![Code Climate](https://codeclimate.com/github/elastic/elasticsearch-rails/badges/gpa.svg)](https://codeclimate.com/github/elastic/elasticsearch-rails)

To work on the code, clone the repository and install all dependencies first:

```
git clone https://github.com/elastic/elasticsearch-rails.git
cd elasticsearch-rails/
bundle install
rake bundle:install
```

### Running the Test Suite

You can run unit and integration tests for each sub-project by running the respective Rake tasks in their folders.

You can also unit, integration, or both tests for all sub-projects from the top-level directory:

    rake test:all

The test suite expects an Elasticsearch cluster running on port 9250, and **will delete all the data**. You can launch an isolated, in-memory Elasticsearch cluster with the following Rake task:

    TEST_CLUSTER_COMMAND=/tmp/builds/elasticsearch-2.0.0-SNAPSHOT/bin/elasticsearch TEST_CLUSTER_NODES=1 bundle exec rake test:cluster:start

See more information in the documentation  for the [`elasticsearch-extensions`](https://github.com/elasticsearch/elasticsearch-ruby/tree/master/elasticsearch-extensions#testcluster) gem.

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
