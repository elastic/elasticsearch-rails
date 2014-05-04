# Elasticsearch::Model

The `elasticsearch-model` library builds on top of the
the [`elasticsearch`](https://github.com/elasticsearch/elasticsearch-ruby) library.

It aims to simplify integration of Ruby classes ("models"), commonly found
e.g. in [Ruby on Rails](http://rubyonrails.org) applications, with the
[Elasticsearch](http://www.elasticsearch.org) search and analytics engine.

The library is compatible with Ruby 1.9.3 and higher.

## Installation

Install the package from [Rubygems](https://rubygems.org):

    gem install elasticsearch-model

To use an unreleased version, either add it to your `Gemfile` for [Bundler](http://bundler.io):

    gem 'elasticsearch-model', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'

or install it from a source code checkout:

    git clone https://github.com/elasticsearch/elasticsearch-rails.git
    cd elasticsearch-rails/elasticsearch-model
    bundle install
    rake install


## Usage

Let's suppose you have an `Article` model:

```ruby
require 'active_record'
ActiveRecord::Base.establish_connection( adapter: 'sqlite3', database: ":memory:" )
ActiveRecord::Schema.define(version: 1) { create_table(:articles) { |t| t.string :title } }

class Article < ActiveRecord::Base; end

Article.create title: 'Quick brown fox'
Article.create title: 'Fast black dogs'
Article.create title: 'Swift green frogs'
```

### Setup

To add the Elasticsearch integration for this model, require `elasticsearch/model`
and include the main module in your class:

```ruby
require 'elasticsearch/model'

class Article < ActiveRecord::Base
  include Elasticsearch::Model
end
```

This will extend the model with functionality related to Elasticsearch.

#### Feature Extraction Pattern

Instead of including the `Elasticsearch::Model` module directly in your model,
you can include it in a "concern" or "trait" module, which is quite common pattern in Rails applications,
using e.g.  `ActiveSupport::Concern` as the instrumentation:

```ruby
# In: app/models/concerns/searchable.rb
#
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    mapping do
      # ...
    end

    def self.search(query)
      # ...
    end
  end
end

# In: app/models/article.rb
#
class Article
  include Searchable
end
```

#### The `__elasticsearch__` Proxy

The `Elasticsearch::Model` module contains a big amount of class and instance methods to provide
all its functionality. To prevent polluting your model namespace, this functionality is primarily
available via the `__elasticsearch__` class and instance level proxy methods;
see the `Elasticsearch::Model::Proxy` class documentation for technical information.

The module will include important methods, such as `search`, into the class or module only
when they haven't been defined already. Following two calls are thus functionally equivalent:

```ruby
Article.__elasticsearch__.search 'fox'
Article.search 'fox'
```

See the `Elasticsearch::Model` module documentation for technical information.

### The Elasticsearch client

The module will set up a [client](https://github.com/elasticsearch/elasticsearch-ruby/tree/master/elasticsearch),
connected to `localhost:9200`, by default. You can access and use it as any other `Elasticsearch::Client`:

```ruby
Article.__elasticsearch__.client.cluster.health
# => { "cluster_name"=>"elasticsearch", "status"=>"yellow", ... }
```

To use a client with different configuration, just set up a client for the model:

```ruby
Article.__elasticsearch__.client = Elasticsearch::Client.new host: 'api.server.org'
```

Or configure the client for all models:

```ruby
Elasticsearch::Model.client = Elasticsearch::Client.new log: true
```

You might want to do this during you application bootstrap process, e.g. in a Rails initializer.

Please refer to the
[`elasticsearch-transport`](https://github.com/elasticsearch/elasticsearch-ruby/tree/master/elasticsearch-transport)
library documentation for all the configuration options, and to the
[`elasticsearch-api`](http://rubydoc.info/gems/elasticsearch-api) library documentation
for information about the Ruby client API.

### Importing the data

The first thing you'll want to do is importing your data into the index:

```ruby
Article.import
# => 0
```

It's possible to import only records from a specific `scope`, transform the batch with the `transform`
and `preprocess` options, or re-create the index by deleting it and creating it with correct mapping with the `force` option -- look for examples in the method documentation.

No errors were reported during importing, so... let's search the index!


### Searching

For starters, we can try the "simple" type of search:

```ruby
response = Article.search 'fox dogs'

response.took
# => 3

response.results.total
# => 2

response.results.first._score
# => 0.02250402

response.results.first._source.title
# => "Quick brown fox"
```

#### Search results

The returned `response` object is a rich wrapper around the JSON returned from Elasticsearch,
providing access to response metadata and the actual results ("hits").

Each "hit" is wrapped in the `Result` class, and provides method access
to its properties via [`Hashie::Mash`](http://github.com/intridea/hashie).

The `results` object supports the `Enumerable` interface:

```ruby
response.results.map { |r| r._source.title }
# => ["Quick brown fox", "Fast black dogs"]

response.results.select { |r| r.title =~ /^Q/ }
# => [#<Elasticsearch::Model::Response::Result:0x007 ... "_source"=>{"title"=>"Quick brown fox"}}>]
```

In fact, the `response` object will delegate `Enumerable` methods to `results`:

```ruby
response.any? { |r| r.title =~ /fox|dog/ }
# => true
```

To use `Array`'s methods (including any _ActiveSupport_ extensions), just call `to_a` on the object:

```ruby
response.to_a.last.title
# "Fast black dogs"
```

#### Search results as database records

Instead of returning documents from Elasticsearch, the `records` method will return a collection
of model instances, fetched from the primary database, ordered by score:

```ruby
response.records.to_a
# Article Load (0.3ms)  SELECT "articles".* FROM "articles" WHERE "articles"."id" IN (1, 2)
# => [#<Article id: 1, title: "Quick brown fox">, #<Article id: 2, title: "Fast black dogs">]
```

The returned object is the genuine collection of model instances returned by your database,
i.e. `ActiveRecord::Relation` for ActiveRecord, or `Mongoid::Criteria` in case of MongoDB. This allows you to
chain other methods on top of search results, as you would normally do:

```ruby
response.records.where(title: 'Quick brown fox').to_a
# Article Load (0.2ms)  SELECT "articles".* FROM "articles" WHERE "articles"."id" IN (1, 2) AND "articles"."title" = 'Quick brown fox'
# => [#<Article id: 1, title: "Quick brown fox">]

response.records.records.class
# => ActiveRecord::Relation::ActiveRecord_Relation_Article
```

The ordering of the records by score will be preserved, unless you explicitely specify a different
order in your model query language:

```ruby
response.records.order(:title).to_a
# Article Load (0.2ms)  SELECT "articles".* FROM "articles" WHERE "articles"."id" IN (1, 2) ORDER BY "articles".title ASC
# => [#<Article id: 2, title: "Fast black dogs">, #<Article id: 1, title: "Quick brown fox">]
```

The `records` method returns the real instances of your model, which is useful when you want to access your
model methods -- at the expense of slowing down your application, of course.
In most cases, working with `results` coming from Elasticsearch is sufficient, and much faster. See the
[`elasticsearch-rails`](https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-rails)
library for more information about compatibility with the Ruby on Rails framework.

When you want to access both the database `records` and search `results`, use the `each_with_hit`
(or `map_with_hit`) iterator:

```ruby
response.records.each_with_hit { |record, hit| puts "* #{record.title}: #{hit._score}" }
# * Quick brown fox: 0.02250402
# * Fast black dogs: 0.02250402
```

#### Pagination

You can implement pagination with the `from` and `size` search parameters. However, search results
can be automatically paginated with the [`kaminari`](http://rubygems.org/gems/kaminari) or
[`will_paginate`](https://github.com/mislav/will_paginate) gems.

If Kaminari or WillPaginate is loaded, use the familiar paging methods:

```ruby
response.page(2).results
response.page(2).records
```

In a Rails controller, use the the `params[:page]` parameter to paginate through results:

```ruby
@articles = Article.search(params[:q]).page(params[:page]).records

@articles.current_page
# => 2
@articles.next_page
# => 3
```
To initialize and include the Kaminari pagination support manually:

```ruby
Kaminari::Hooks.init
Elasticsearch::Model::Response::Response.__send__ :include, Elasticsearch::Model::Response::Pagination::Kaminari
```

#### The Elasticsearch DSL

In most situation, you'll want to pass the search definition
in the Elasticsearch [domain-specific language](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html) to the client:

```ruby
response = Article.search query:     { match:  { title: "Fox Dogs" } },
                          highlight: { fields: { title: {} } }

response.results.first.highlight.title
# ["Quick brown <em>fox</em>"]
```

You can pass any object which implements a `to_hash` method, or you can use your favourite JSON builder
to build the search definition as a JSON string:

```ruby
require 'jbuilder'

query = Jbuilder.encode do |json|
  json.query do
    json.match do
      json.title do
        json.query "fox dogs"
      end
    end
  end
end

response = Article.search query
response.results.first.title
# => "Quick brown fox"
```

### Index Configuration

For proper search engine function, it's often necessary to configure the index properly.
The `Elasticsearch::Model` integration provides class methods to set up index settings and mappings.

```ruby
class Article
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :title, analyzer: 'english', index_options: 'offsets'
    end
  end
end

Article.mappings.to_hash
# => {
#      :article => {
#        :dynamic => "false",
#        :properties => {
#          :title => {
#            :type          => "string",
#            :analyzer      => "english",
#            :index_options => "offsets"
#          }
#        }
#      }
#    }

Article.settings.to_hash
# { :index => { :number_of_shards => 1 } }
```

You can use the defined settings and mappings to create an index with desired configuration:

```ruby
Article.__elasticsearch__.client.indices.delete index: Article.index_name rescue nil
Article.__elasticsearch__.client.indices.create \
  index: Article.index_name,
  body: { settings: Article.settings.to_hash, mappings: Article.mappings.to_hash }
```

There's a shortcut available for this common operation (convenient e.g. in tests):

```ruby
Article.__elasticsearch__.create_index! force: true
Article.__elasticsearch__.refresh_index!
```

By default, index name and document type will be inferred from your class name,
you can set it explicitely, however:

```ruby
class Article
  index_name    "articles-#{Rails.env}"
  document_type "post"
end
```

### Updating the Documents in the Index

Usually, we need to update the Elasticsearch index when records in the database are created, updated or deleted;
use the `index_document`, `update_document` and `delete_document` methods, respectively:

```ruby
Article.first.__elasticsearch__.index_document
# => {"ok"=>true, ... "_version"=>2}
```

#### Automatic Callbacks

You can automatically update the index whenever the record changes, by including
the `Elasticsearch::Model::Callbacks` module in your model:

```ruby
class Article
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
end

Article.first.update_attribute :title, 'Updated!'

Article.search('*').map { |r| r.title }
# => ["Updated!", "Lime green frogs", "Fast black dogs"]
```

The automatic callback on record update keeps track of changes in your model
(via [`ActiveModel::Dirty`](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html)-compliant implementation),
and performs a _partial update_ when this support is available.

The automatic callbacks are implemented in database adapters coming with `Elasticsearch::Model`. You can easily
implement your own adapter: please see the relevant chapter below.

#### Custom Callbacks

In case you would need more control of the indexing process, you can implement these callbacks yourself,
by hooking into `after_create`, `after_save`, `after_update` or `after_destroy` operations:

```ruby
class Article
  include Elasticsearch::Model

  after_save    { logger.debug ["Updating document... ", index_document ].join }
  after_destroy { logger.debug ["Deleting document... ", delete_document].join }
end
```

For ActiveRecord-based models, you need to hook into the `after_commit` callback, to protect
your data against inconsistencies caused by transaction rollbacks:

```ruby
class Article < ActiveRecord::Base
  include Elasticsearch::Model

  after_commit on: [:create] do
    index_document if self.published?
  end

  after_commit on: [:update] do
    update_document if self.published?
  end

  after_commit on: [:destroy] do
    delete_document if self.published?
  end
end
```

#### Asynchronous Callbacks

Of course, you're still performing an HTTP request during your database transaction, which is not optimal
for large-scale applications. A better option would be to process the index operations in background,
with a tool like [_Resque_](https://github.com/resque/resque) or [_Sidekiq_](https://github.com/mperham/sidekiq):

```ruby
class Article
  include Elasticsearch::Model

  after_save    { Indexer.perform_async(:index,  self.id) }
  after_destroy { Indexer.perform_async(:delete, self.id) }
end
```

An example implementation of the `Indexer` worker class could look like this:

```ruby
class Indexer
  include Sidekiq::Worker
  sidekiq_options queue: 'elasticsearch', retry: false

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  Client = Elasticsearch::Client.new host: 'localhost:9200', logger: Logger

  def perform(operation, record_id)
    logger.debug [operation, "ID: #{record_id}"]

    case operation.to_s
      when /index/
        record = Article.find(record_id)
        Client.index  index: 'articles', type: 'article', id: record.id, body: record.as_indexed_json
      when /delete/
        Client.delete index: 'articles', type: 'article', id: record_id
      else raise ArgumentError, "Unknown operation '#{operation}'"
    end
  end
end
```

Start the _Sidekiq_ workers with `bundle exec sidekiq --queue elasticsearch --verbose` and
update a model:

```ruby
Article.first.update_attribute :title, 'Updated'
```

You'll see the job being processed in the console where you started the _Sidekiq_ worker:

```
Indexer JID-eb7e2daf389a1e5e83697128 DEBUG: ["index", "ID: 7"]
Indexer JID-eb7e2daf389a1e5e83697128 INFO: PUT http://localhost:9200/articles/article/1 [status:200, request:0.004s, query:n/a]
Indexer JID-eb7e2daf389a1e5e83697128 DEBUG: > {"id":1,"title":"Updated", ...}
Indexer JID-eb7e2daf389a1e5e83697128 DEBUG: < {"ok":true,"_index":"articles","_type":"article","_id":"1","_version":6}
Indexer JID-eb7e2daf389a1e5e83697128 INFO: done: 0.006 sec
```

### Model Serialization

By default, the model instance will be serialized to JSON using the `as_indexed_json` method,
which is defined automatically by the `Elasticsearch::Model::Serializing` module:

```ruby
Article.first.__elasticsearch__.as_indexed_json
# => {"id"=>1, "title"=>"Quick brown fox"}
```

If you want to customize the serialization, just implement the `as_indexed_json` method yourself,
for instance with the [`as_json`](http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html#method-i-as_json) method:

```ruby
class Article
  include Elasticsearch::Model

  def as_indexed_json(options={})
    as_json(only: 'title')
  end
end

Article.first.as_indexed_json
# => {"title"=>"Quick brown fox"}
```

The re-defined method will be used in the indexing methods, such as `index_document`.

Please note that in Rails 3, you need to either set `include_root_in_json: false`, or prevent adding
the "root" in the JSON representation with other means.

#### Relationships and Associations

When you have a more complicated structure/schema, you need to customize the `as_indexed_json` method -
or perform the indexing separately, on your own.
For example, let's have an `Article` model, which _has_many_ `Comment`s,
`Author`s and `Categories`. We might want to define the serialization like this:

```ruby
def as_indexed_json(options={})
  self.as_json(
    include: { categories: { only: :title},
               authors:    { methods: [:full_name], only: [:full_name] },
               comments:   { only: :text }
             })
end

Article.first.as_indexed_json
# => { "id"         => 1,
#      "title"      => "First Article",
#      "created_at" => 2013-12-03 13:39:02 UTC,
#      "updated_at" => 2013-12-03 13:39:02 UTC,
#      "categories" => [ { "title" => "One" } ],
#      "authors"    => [ { "full_name" => "John Smith" } ],
#      "comments"   => [ { "text" => "First comment" } ] }
```

Of course, when you want to use the automatic indexing callbacks, you need to hook into the appropriate
_ActiveRecord_ callbacks -- please see the full example in `examples/activerecord_associations.rb`.

### Other ActiveModel Frameworks

The `Elasticsearch::Model` module is fully compatible with any ActiveModel-compatible model, such as _Mongoid_:

```ruby
require 'mongoid'

Mongoid.connect_to 'articles'

class Article
  include Mongoid::Document

  field :id,    type: String
  field :title, type: String

  attr_accessible :id, :title, :published_at

  include Elasticsearch::Model

  def as_indexed_json(options={})
    as_json(except: [:id, :_id])
  end
end

Article.create id: '1', title: 'Quick brown fox'
Article.import

response = Article.search 'fox';
response.records.to_a
#  MOPED: 127.0.0.1:27017 QUERY        database=articles collection=articles selector={"_id"=>{"$in"=>["1"]}} ...
# => [#<Article _id: 1, id: nil, title: "Quick brown fox", published_at: nil>]
```

Full examples for CouchBase, DataMapper, Mongoid, Ohm and Riak models can be found in the `examples` folder.

### Adapters

To support various "OxM" (object-relational- or object-document-mapper) implementations and frameworks,
the `Elasticsearch::Model` integration supports an "adapter" concept.

An adapter provides implementations for common behaviour, such as fetching records from the database,
hooking into model callbacks for automatic index updates, or efficient bulk loading from the database.
The integration comes with adapters for _ActiveRecord_ and _Mongoid_ out of the box.

Writing an adapter for your favourite framework is straightforward -- let's see
a simplified adapter for [_DataMapper_](http://datamapper.org):

```ruby
module DataMapperAdapter

  # Implement the interface for fetching records
  #
  module Records
    def records
      klass.all(id: @ids)
    end

    # ...
  end
end

# Register the adapter
#
Elasticsearch::Model::Adapter.register(
  DataMapperAdapter,
  lambda { |klass| defined?(::DataMapper::Resource) and klass.ancestors.include?(::DataMapper::Resource) }
)
```

Require the adapter and include `Elasticsearch::Model` in the class:

```ruby
require 'datamapper_adapter'

class Article
  include DataMapper::Resource
  include Elasticsearch::Model

  property :id,    Serial
  property :title, String
end
```

When accessing the `records` method of the response, for example,
the implementation from our adapter will be used now:

```ruby
response = Article.search 'foo'

response.records.to_a
# ~  (0.000057) SELECT "id", "title", "published_at" FROM "articles" WHERE "id" IN (3, 1) ORDER BY "id"
# => [#<Article @id=1 @title="Foo" @published_at=nil>, #<Article @id=3 @title="Foo Foo" @published_at=nil>]

response.records.records.class
# => DataMapper::Collection
```

More examples can be found in the `examples` folder. Please see the `Elasticsearch::Model::Adapter`
module and its submodules for technical information.

## Development and Community

For local development, clone the repository and run `bundle install`. See `rake -T` for a list of
available Rake tasks for running tests, generating documentation, starting a testing cluster, etc.

Bug fixes and features must be covered by unit tests.

Github's pull requests and issues are used to communicate, send bug reports and code contributions.

To run all tests against a test Elasticsearch cluster, use a command like this:

```bash
curl -# https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.0.RC1.tar.gz | tar xz -C tmp/
SERVER=start TEST_CLUSTER_COMMAND=$PWD/tmp/elasticsearch-1.0.0.RC1/bin/elasticsearch bundle exec rake test:all
```

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
