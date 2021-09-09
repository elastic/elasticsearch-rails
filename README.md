# Elasticsearch

[![Ruby 2.7](https://github.com/elastic/elasticsearch-rails/workflows/Ruby%202.7/badge.svg)](https://github.com/elastic/elasticsearch-rails/actions)
[![Ruby 2.6](https://github.com/elastic/elasticsearch-rails/workflows/Ruby%202.6/badge.svg)](https://github.com/elastic/elasticsearch-rails/actions)
[![Ruby 2.5](https://github.com/elastic/elasticsearch-rails/workflows/Ruby%202.5/badge.svg)](https://github.com/elastic/elasticsearch-rails/actions)
[![Ruby 2.4](https://github.com/elastic/elasticsearch-rails/workflows/Ruby%202.4/badge.svg)](https://github.com/elastic/elasticsearch-rails/actions)
[![JRuby](https://github.com/elastic/elasticsearch-rails/workflows/JRuby/badge.svg)](https://github.com/elastic/elasticsearch-rails/actions)
[![Code Climate](https://codeclimate.com/github/elastic/elasticsearch-rails/badges/gpa.svg)](https://codeclimate.com/github/elastic/elasticsearch-rails)

This repository contains various Ruby and Rails integrations for [Elasticsearch](http://elasticsearch.org):

* ActiveModel integration with adapters for ActiveRecord and Mongoid
* _Repository pattern_ based persistence layer for Ruby objects
* Enumerable-based wrapper for search results
* ActiveRecord::Relation-based wrapper for returning search results as records
* Convenience model methods such as `search`, `mapping`, `import`, etc
* Rake tasks for importing the data
* Support for Kaminari and WillPaginate pagination
* Integration with Rails' instrumentation framework
* Templates for generating example Rails application

Elasticsearch client and Ruby API is provided by the
**[elasticsearch-ruby](https://github.com/elastic/elasticsearch-ruby)** project.

## Installation

Install each library from [Rubygems](https://rubygems.org/gems/elasticsearch):

    gem install elasticsearch-model
    gem install elasticsearch-rails

To use an unreleased version, add it to your `Gemfile` for [Bundler](http://bundler.io):

```ruby
gem 'elasticsearch-model', github: 'elastic/elasticsearch-rails', branch: '5.x'
gem 'elasticsearch-rails', github: 'elastic/elasticsearch-rails', branch: '5.x'
```

## Compatibility

The libraries are compatible with Ruby 2.4 and higher.

The version numbers follow the Elasticsearch major versions. The `main` branch is compatible with the latest Elasticsearch stack stable release.

| Rubygem       |   | Elasticsearch |
|:-------------:|:-:| :-----------: |
| 0.1           | → | 1.x           |
| 2.x           | → | 2.x           |
| 5.x           | → | 5.x           |
| 6.x           | → | 6.x           |
| main          | → | 7.x           |

Use a release that matches the major version of Elasticsearch in your stack. Each client version is backwards compatible with all minor versions of the same major version.

Check out [Elastic product end of life dates](https://www.elastic.co/support/eol) to learn which releases are still actively supported and tested.

## Usage

This project is split into three separate gems:

* [**`elasticsearch-model`**](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-model),
  which contains search integration for Ruby/Rails models such as ActiveRecord::Base and Mongoid,

* [**`elasticsearch-persistence`**](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-persistence),
  which provides a standalone persistence layer for Ruby/Rails objects and models

* [**`elasticsearch-rails`**](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-rails),
  which contains various features for Ruby on Rails applications

Example of a basic integration into an ActiveRecord-based model:

```ruby
require 'elasticsearch/model'

class Article < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
end

# Index creation right at import time is not encouraged.
# Typically, you would call create_index! asynchronously (e.g. in a cron job)
# However, we are adding it here so that this usage example can run correctly.
Article.__elasticsearch__.create_index!
Article.import

@articles = Article.search('foobar').records
```

You can generate a simple Ruby on Rails application with a single command
(see the [other available templates](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-rails#rails-application-templates)). You'll need to have an Elasticsearch cluster running on your system before generating the app. The easiest way of getting this set up is by running it with Docker with this command:

```bash
  docker run \
    --name elasticsearch-rails-searchapp \
    --publish 9200:9200 \
    --env "discovery.type=single-node" \
    --env "cluster.name=elasticsearch-rails" \
    --env "cluster.routing.allocation.disk.threshold_enabled=false" \
    --rm \
    docker.elastic.co/elasticsearch/elasticsearch-oss:7.6.0
```

Once Elasticsearch is running, you can generate the simple app with this command:

```bash
rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/main/elasticsearch-rails/lib/rails/templates/01-basic.rb
```

Example of using Elasticsearch as a repository for a Ruby domain object:

```ruby
class Article
  attr_accessor :title
end

require 'elasticsearch/persistence'
repository = Elasticsearch::Persistence::Repository.new

repository.save Article.new(title: 'Test')
# POST http://localhost:9200/repository/article
# => {"_index"=>"repository", "_type"=>"article", "_id"=>"Ak75E0U9Q96T5Y999_39NA", ...}
```

**Please refer to each library documentation for detailed information and examples.**

### Model

* [[README]](https://github.com/elastic/elasticsearch-rails/blob/main/elasticsearch-model/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-model/)
* [[Test Suite]](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-model/spec/elasticsearch/model)

### Persistence

* [[README]](https://github.com/elastic/elasticsearch-rails/blob/main/elasticsearch-persistence/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-persistence/)
* [[Test Suite]](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-persistence/spec)

### Rails

* [[README]](https://github.com/elastic/elasticsearch-rails/blob/main/elasticsearch-rails/README.md)
* [[Documentation]](http://rubydoc.info/gems/elasticsearch-rails)
* [[Test Suite]](https://github.com/elastic/elasticsearch-rails/tree/main/elasticsearch-rails/spec)

## Development

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

The test suite expects an Elasticsearch cluster running on port 9250, and **will delete all the data**.

## License

This software is licensed under the Apache 2 license, quoted below.

    Licensed to Elasticsearch B.V. under one or more contributor
    license agreements. See the NOTICE file distributed with
    this work for additional information regarding copyright
    ownership. Elasticsearch B.V. licenses this file to you under
    the Apache License, Version 2.0 (the "License"); you may
    not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
    	http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
