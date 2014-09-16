# Elasticsearch::Persistence

Persistence layer for Ruby domain objects in Elasticsearch, using the Repository and ActiveRecord patterns.

The library is compatible with Ruby 1.9.3 (or higher) and Elasticsearch 1.0 (or higher).

## Installation

Install the package from [Rubygems](https://rubygems.org):

    gem install elasticsearch-persistence

To use an unreleased version, either add it to your `Gemfile` for [Bundler](http://bundler.io):

    gem 'elasticsearch-persistence', git: 'git://github.com/elasticsearch/elasticsearch-rails.git'

or install it from a source code checkout:

    git clone https://github.com/elasticsearch/elasticsearch-rails.git
    cd elasticsearch-rails/elasticsearch-persistence
    bundle install
    rake install

## Usage

### The Repository Pattern

The `Elasticsearch::Persistence::Repository` module provides an implementation of the
[repository pattern](http://martinfowler.com/eaaCatalog/repository.html) and allows
to save, delete, find and search objects stored in Elasticsearch, as well as configure
mappings and settings for the index.

Let's have a simple plain old Ruby object (PORO):

```ruby
class Note
  attr_reader :attributes

  def initialize(attributes={})
    @attributes = attributes
  end

  def to_hash
    @attributes
  end
end
```

Let's create a default, "dumb" repository, as a first step:

```ruby
require 'elasticsearch/persistence'
repository = Elasticsearch::Persistence::Repository.new
```

We can save a `Note` instance into the repository...

```ruby
note = Note.new id: 1, text: 'Test'

repository.save(note)
# PUT http://localhost:9200/repository/note/1 [status:201, request:0.210s, query:n/a]
# > {"id":1,"text":"Test"}
# < {"_index":"repository","_type":"note","_id":"1","_version":1,"created":true}
```

...find it...

```ruby
n = repository.find(1)
# GET http://localhost:9200/repository/_all/1 [status:200, request:0.003s, query:n/a]
# < {"_index":"repository","_type":"note","_id":"1","_version":2,"found":true, "_source" : {"id":1,"text":"Test"}}
=> <Note:0x007fcbfc0c4980 @attributes={"id"=>1, "text"=>"Test"}>
```

...search for it...

```ruby
repository.search(query: { match: { text: 'test' } }).first
# GET http://localhost:9200/repository/_search [status:200, request:0.005s, query:0.002s]
# > {"query":{"match":{"text":"test"}}}
# < {"took":2, ... "hits":{"total":1, ... "hits":[{ ... "_source" : {"id":1,"text":"Test"}}]}}
=> <Note:0x007fcbfc1c7b70 @attributes={"id"=>1, "text"=>"Test"}>
```

...or delete it:

```ruby
repository.delete(note)
# DELETE http://localhost:9200/repository/note/1 [status:200, request:0.014s, query:n/a]
# < {"found":true,"_index":"repository","_type":"note","_id":"1","_version":3}
=> {"found"=>true, "_index"=>"repository", "_type"=>"note", "_id"=>"1", "_version"=>2}
```

The repository module provides a number of features and facilities to configure and customize the behaviour:

* Configuring the Elasticsearch [client](https://github.com/elasticsearch/elasticsearch-ruby#usage) being used
* Setting the index name, document type, and object class for deserialization
* Composing mappings and settings for the index
* Creating, deleting or refreshing the index
* Finding or searching for documents
* Providing access both to domain objects and hits for search results
* Providing access to the Elasticsearch response for search results (aggregations, total, ...)
* Defining the methods for serialization and deserialization

You can use the default repository class, or include the module in your own. Let's review it in detail.

#### The Default Class

For simple cases, you can use the default, bundled repository class, and configure/customize it:

```ruby
repository = Elasticsearch::Persistence::Repository.new do
  # Configure the Elasticsearch client
  client Elasticsearch::Client.new url: ENV['ELASTICSEARCH_URL'], log: true

  # Set a custom index name
  index :my_notes

  # Set a custom document type
  type  :my_note

  # Specify the class to inicialize when deserializing documents
  klass Note

  # Configure the settings and mappings for the Elasticsearch index
  settings number_of_shards: 1 do
    mapping do
      indexes :text, analyzer: 'snowball'
    end
  end

  # Customize the serialization logic
  def serialize(document)
    super.merge(my_special_key: 'my_special_stuff')
  end

  # Customize the de-serialization logic
  def deserialize(document)
    puts "# ***** CUSTOM DESERIALIZE LOGIC KICKING IN... *****"
    super
  end
end
```

The custom Elasticsearch client will be used now, with a custom index and type names,
as well as the custom serialization and de-serialization logic.

We can create the index with the desired settings and mappings:

```ruby
repository.create_index! force: true
# PUT http://localhost:9200/my_notes
# > {"settings":{"number_of_shards":1},"mappings":{ ... {"text":{"analyzer":"snowball","type":"string"}}}}}
```

Save the document with extra properties added by the `serialize` method:

```ruby
repository.save(note)
# PUT http://localhost:9200/my_notes/my_note/1
# > {"id":1,"text":"Test","my_special_key":"my_special_stuff"}
{"_index"=>"my_notes", "_type"=>"my_note", "_id"=>"1", "_version"=>4, ... }
```

And `deserialize` it:

```ruby
repository.find(1)
# ***** CUSTOM DESERIALIZE LOGIC KICKING IN... *****
<Note:0x007f9bd782b7a0 @attributes={... "my_special_key"=>"my_special_stuff"}>
```

#### A Custom Class

In most cases, though, you'll want to use a custom class for the repository, so let's do that:

```ruby
require 'base64'

class NoteRepository
  include Elasticsearch::Persistence::Repository

  def initialize(options={})
    index  options[:index] || 'notes'
    client Elasticsearch::Client.new url: options[:url], log: options[:log]
  end

  klass Note

  settings number_of_shards: 1 do
    mapping do
      indexes :text,  analyzer: 'snowball'
      # Do not index images
      indexes :image, index: 'no'
    end
  end

  # Base64 encode the "image" field in the document
  #
  def serialize(document)
    hash = document.to_hash.clone
    hash['image'] = Base64.encode64(hash['image']) if hash['image']
    hash.to_hash
  end

  # Base64 decode the "image" field in the document
  #
  def deserialize(document)
    hash = document['_source']
    hash['image'] = Base64.decode64(hash['image']) if hash['image']
    klass.new hash
  end
end
```

Include the `Elasticsearch::Persistence::Repository` module to add the repository methods into the class.

You can customize the repository in the familiar way, by calling the DSL-like methods.

You can implement a custom initializer for your repository, add complex logic in its
class and instance methods -- in general, have all the freedom of a standard Ruby class.

```ruby
repository = NoteRepository.new url: 'http://localhost:9200', log: true

# Configure the repository instance
repository.index = 'notes_development'
repository.client.transport.logger.formatter = proc { |s, d, p, m| "\e[2m# #{m}\n\e[0m" }

repository.create_index! force: true

note = Note.new 'id' => 1, 'text' => 'Document with image', 'image' => '... BINARY DATA ...'

repository.save(note)
# PUT http://localhost:9200/notes_development/note/1
# > {"id":1,"text":"Document with image","image":"Li4uIEJJTkFSWSBEQVRBIC4uLg==\n"}
puts repository.find(1).attributes['image']
# GET http://localhost:9200/notes_development/note/1
# < {... "_source" : { ... "image":"Li4uIEJJTkFSWSBEQVRBIC4uLg==\n"}}
# => ... BINARY DATA ...
```

#### Methods Provided by the Repository

##### Client

The repository uses the standard Elasticsearch [client](https://github.com/elasticsearch/elasticsearch-ruby#usage),
which is accessible with the `client` getter and setter methods:

```ruby
repository.client = Elasticsearch::Client.new url: 'http://search.server.org'
repository.client.transport.logger = Logger.new(STDERR)
```

##### Naming

The `index` method specifies the Elasticsearch index to use for storage, lookup and search
(when not set, the value is inferred from the repository class name):

```ruby
repository.index = 'notes_development'
```

The `type` method specifies the Elasticsearch document type to use for storage, lookup and search
(when not set, the value is inferred from the document class name, or `_all` is used):

```ruby
repository.type = 'my_note'
```

The `klass` method specifies the Ruby class name to use when initializing objects from
documents retrieved from the repository (when not set, the value is inferred from the
document `_type` as fetched from Elasticsearch):

```ruby
repository.klass = MyNote
```

##### Index Configuration

The `settings` and `mappings` methods, provided by the
[`elasticsearch-model`](http://rubydoc.info/gems/elasticsearch-model/Elasticsearch/Model/Indexing/ClassMethods)
gem, allow to configure the index properties:

```ruby
repository.settings number_of_shards: 1
repository.settings.to_hash
# => {:number_of_shards=>1}

repository.mappings { indexes :title, analyzer: 'snowball' }
repository.mappings.to_hash
# => { :note => {:properties=> ... }}
```

The convenience methods `create_index!`, `delete_index!` and `refresh_index!` allow you to manage the index lifecycle.

##### Serialization

The `serialize` and `deserialize` methods allow you to customize the serialization of the document when passing it
to the storage, and the initialization procedure when loading it from the storage:

```ruby
class NoteRepository
  def serialize(document)
    Hash[document.to_hash.map() { |k,v|  v.upcase! if k == :title; [k,v] }]
  end
  def deserialize(document)
    MyNote.new ActiveSupport::HashWithIndifferentAccess.new(document['_source']).deep_symbolize_keys
  end
end
```

##### Storage

The `save` method allows you to store a domain object in the repository:

```ruby
note = Note.new id: 1, title: 'Quick Brown Fox'
repository.save(note)
# => {"_index"=>"notes_development", "_type"=>"my_note", "_id"=>"1", "_version"=>1, "created"=>true}
```

The `update` method allows you to perform a partial update of a document in the repository.
Use either a partial document:

```ruby
repository.update id: 1, title: 'UPDATED',  tags: []
# => {"_index"=>"notes_development", "_type"=>"note", "_id"=>"1", "_version"=>2}
```

Or a script (optionally with parameters):

```ruby
repository.update 1, script: 'if (!ctx._source.tags.contains(t)) { ctx._source.tags += t }', params: { t: 'foo' }
# => {"_index"=>"notes_development", "_type"=>"note", "_id"=>"1", "_version"=>3}
```


The `delete` method allows to remove objects from the repository (pass either the object itself or its ID):

```ruby
repository.delete(note)
repository.delete(1)
```

##### Finding

The `find` method allows to find one or many documents in the storage and returns them as deserialized Ruby objects:

```ruby
repository.save Note.new(id: 2, title: 'Fast White Dog')

note = repository.find(1)
# => <MyNote ... QUICK BROWN FOX>

notes = repository.find(1, 2)
# => [<MyNote... QUICK BROWN FOX>, <MyNote ... FAST WHITE DOG>]
```

When the document with a specific ID isn't found, a `nil` is returned instead of the deserialized object:

```ruby
notes = repository.find(1, 3, 2)
# => [<MyNote ...>, nil, <MyNote ...>]
```

Handle the missing objects in the application code, or call `compact` on the result.

##### Search

The `search` method to retrieve objects from the repository by a query string or definition in the Elasticsearch DSL:

```ruby
repository.search('fox or dog').to_a
# GET http://localhost:9200/notes_development/my_note/_search?q=fox
# => [<MyNote ... FOX ...>, <MyNote ... DOG ...>]

repository.search(query: { match: { title: 'fox dog' } }).to_a
# GET http://localhost:9200/notes_development/my_note/_search
# > {"query":{"match":{"title":"fox dog"}}}
# => [<MyNote ... FOX ...>, <MyNote ... DOG ...>]
```

The returned object is an instance of the `Elasticsearch::Persistence::Repository::Response::Results` class,
which provides access to the results, the full returned response and hits.

```ruby
results = repository.search(query: { match: { title: 'fox dog' } })

# Iterate over the objects
#
results.each do |note|
  puts "* #{note.attributes[:title]}"
end
# * QUICK BROWN FOX
# * FAST WHITE DOG

# Iterate over the objects and hits
#
results.each_with_hit do |note, hit|
  puts "* #{note.attributes[:title]}, score: #{hit._score}"
end
# * QUICK BROWN FOX, score: 0.29930896
# * FAST WHITE DOG, score: 0.29930896

# Get total results
#
results.total
# => 2

# Access the raw response as a Hashie::Mash instance
results.response._shards.failed
# => 0
```

#### Example Application

An example Sinatra application is available in [`examples/notes/application.rb`](examples/notes/application.rb),
and demonstrates a rich set of features:

* How to create and configure a custom repository class
* How to work with a plain Ruby class as the domain object
* How to integrate the repository with a Sinatra application
* How to write complex search definitions, including pagination, highlighting and aggregations
* How to use search results in the application view

### The ActiveRecord Pattern

The `Elasticsearch::Persistence::Model` module provides an implementation of the
active record [pattern](http://www.martinfowler.com/eaaCatalog/activeRecord.html),
with a familiar interface for using Elasticsearch as a persistence layer in
Ruby on Rails applications.

All the methods are documented with comprehensive examples in the source code,
available also online at <http://rubydoc.info/gems/elasticsearch-persistence/Elasticsearch/Persistence/Model>.

#### Installation/Usage

To use the library in a Rails application, add it to your `Gemfile` with a `require` statement:

```ruby
gem "elasticsearch-persistence", require: 'elasticsearch/persistence/model'
```

To use the library without Bundler, install it, and require the file:

```bash
gem install elasticsearch-persistence
```

```ruby
# In your code
require 'elasticsearch/persistence/model'
```

#### Model Definition

The integration is implemented by including the module in a Ruby class.
The model attribute definition support is implemented with the
[_Virtus_](https://github.com/solnic/virtus) Rubygem, and the
naming, validation, etc. features with the
[_ActiveModel_](https://github.com/rails/rails/tree/master/activemodel) Rubygem.

```ruby
class Article
  include Elasticsearch::Persistence::Model

  # Define a plain `title` attribute
  #
  attribute :title,  String

  # Define an `author` attribute, with multiple analyzers for this field
  #
  attribute :author, String, mapping: { fields: {
                               author: { type: 'string'},
                               raw:    { type: 'string', analyzer: 'keyword' }
                             } }


  # Define a `views` attribute, with default value
  #
  attribute :views,  Integer, default: 0, mapping: { type: 'integer' }

  # Validate the presence of the `title` attribute
  #
  validates :title, presence: true

  # Execute code after saving the model.
  #
  after_save { puts "Successfuly saved: #{self}" }
end
```

Attribute validations work like for any other _ActiveModel_-compatible implementation:

```ruby
article = Article.new                                                                                             # => #<Article { ... }>

article.valid?
# => false

article.errors.to_a
# => ["Title can't be blank"]
```

#### Persistence

We can create a new article in the database...

```ruby
Article.create id: 1, title: 'Test', author: 'John'
# PUT http://localhost:9200/articles/article/1 [status:201, request:0.015s, query:n/a]
```

... and find it:

```ruby
article = Article.find(1)
# => #<Article { ... }>

article._index
# => "articles"

article.id
# => "1"

article.title
# => "Test"
```

To update the model, either update the attribute and save the model:

```ruby
article.title = 'Updated'

article.save
# => {"_index"=>"articles", "_type"=>"article", "_id"=>"1", "_version"=>2, "created"=>false}
```

... or use the `update_attributes` method:

```ruby
article.update_attributes title: 'Test', author: 'Mary'
# => {"_index"=>"articles", "_type"=>"article", "_id"=>"1", "_version"=>3}
```

The implementation supports the familiar interface for updating model timestamps:

```ruby
article.touch
# => => { ... "_version"=>4}
```

... and numeric attributes:

```ruby
article.views
# => 0

article.increment :views
article.views
# => 1
```

Any callbacks defined in the model will be triggered during the persistence operations:

```ruby
article.save
# Successfuly saved: #<Article {...}>
```

The model also supports familiar `find_in_batches` and `find_each` methods to efficiently
retrieve big collections of model instances, using the Elasticsearch's _Scan API_:

```ruby
Article.find_each(_source_include: 'title') { |a| puts "===> #{a.title.upcase}" }
# GET http://localhost:9200/articles/article/_search?scroll=5m&search_type=scan&size=20
# GET http://localhost:9200/_search/scroll?scroll=5m&scroll_id=c2Nhb...
# ===> TEST
# GET http://localhost:9200/_search/scroll?scroll=5m&scroll_id=c2Nhb...
# => "c2Nhb..."
```

#### Search

The model class provides a `search` method to retrieve model instances with a regular
search definition, including highlighting, aggregations, etc:

```ruby
results = Article.search query: { match: { title: 'test' } },
                         aggregations: {  authors: { terms: { field: 'author.raw' } } },
                         highlight: { fields: { title: {} } }

puts results.first.title
# Test

puts results.first.hit.highlight['title']
# <em>Test</em>

puts results.response.aggregations.authors.buckets.each { |b| puts "#{b['key']} : #{b['doc_count']}" }
# John : 1
```

#### The Elasticsearch Client

The module will set up a [client](https://github.com/elasticsearch/elasticsearch-ruby/tree/master/elasticsearch),
connected to `localhost:9200`, by default.

To use a client with different configuration:

```ruby
Elasticsearch::Persistence.client = Elasticsearch::Client.new log: true
```

To set up a specific client for a specific model:

```ruby
Article.client = Elasticsearch::Client.new host: 'api.server.org'
```

You might want to do this during you application bootstrap process, e.g. in a Rails initializer.

Please refer to the
[`elasticsearch-transport`](https://github.com/elasticsearch/elasticsearch-ruby/tree/master/elasticsearch-transport)
library documentation for all the configuration options, and to the
[`elasticsearch-api`](http://rubydoc.info/gems/elasticsearch-api) library documentation
for information about the Ruby client API.

#### Accessing the Repository Gateway and the Client

The integration with Elasticsearch is implemented by embedding the repository object in the model.
You can access it through the `gateway` method:

```ruby
Artist.gateway.client.info
# GET http://localhost:9200/ [status:200, request:0.011s, query:n/a]
# => {"status"=>200, "name"=>"Lightspeed", ...}
```

#### Rails Compatibility

The model instances are fully compatible with Rails' conventions and helpers:

```ruby
url_for article
# => "http://localhost:3000/articles/1"

div_for article
# => '<div class="article" id="article_1"></div>'
```

... as well as form values for dates and times:

```ruby
article = Article.new "title" => "Date", "published(1i)"=>"2014", "published(2i)"=>"1", "published(3i)"=>"1"

article.published.iso8601
# => "2014-01-01"
```

The library provides a Rails ORM generator to facilitate building the application scaffolding:

```bash
rails generate scaffold Person name:String email:String birthday:Date --orm=elasticsearch
```

#### Example application

A fully working Ruby on Rails application can be generated with the following command:

```bash
rails new music --force --skip --skip-bundle --skip-active-record --template https://raw.githubusercontent.com/elasticsearch/elasticsearch-rails/master/elasticsearch-persistence/examples/music/template.rb
```

The application demonstrates:

* How to set up model attributes with custom mappings
* How to define model relationships with Elasticsearch's parent/child
* How to configure models to use a common index, and create the index with proper mappings
* How to use Elasticsearch's completion suggester to drive auto-complete functionality
* How to use Elasticsearch-persisted models in Rails' views and forms
* How to write controller tests

The source files for the application are available in the [`examples/music`](examples/music) folder.

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
