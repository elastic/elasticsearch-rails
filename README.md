# Elasticsearch

This repository contains ActiveModel, ActiveRecord and Ruby on Rails integrations for
[Elasticsearch](http://elasticsearch.org):

* ActiveModel integration with adapters for ActiveRecord and Mongoid
* Enumerable-based wrapper for search results
* ActiveRecord::Relation-based wrapper for returning search results as records
* Model methods such as `search`, `mapping`, etc
* Pagination support
* Rails application templates

_NOTE: This is a pre-release version: feedback welcome via Github issues, e-mail or IRC.
       Many more features, such as automatic hooking into Rails' notifications,
       Elasticsearch persistence for models, etc. are planned or being worked on._

## Installation

The libraries are compatible with Ruby 1.9.3 and higher.

Install the `elasticsearch-model` and/or `elasticsearch-rails` package from
[Rubygems](https://rubygems.org/gems/elasticsearch):

    gem install elasticsearch-model elasticsearch-rails --pre

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

This project is split into two separate gems:

* [**`elasticsearch-model`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-model),
  which contains model-related features such as setting up indices, `search` method, pagination, etc

* [**`elasticsearch-rails`**](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-rails),
  which contains features for Ruby on Rails applications

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

You can generate a fully working Ruby on Rails application with a single command:

```bash
rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/01-basic.rb
```

Please refer to each library documentation for detailed information and examples.

### Model

* [[README]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-model/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-model/)
* [[Test Suite]](https://github.com/elasticsearch/elasticsearch-rails/blob/master/elasticsearch-model/test)

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
