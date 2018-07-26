# Elasticsearch::Persistence

Persistence layer for Ruby domain objects in Elasticsearch, using the Repository and ActiveRecord patterns.

## Compatibility

This library is compatible with Ruby 1.9.3 and higher.

The library version numbers follow the Elasticsearch major versions, and the `master` branch
is compatible with the Elasticsearch `master` branch, therefore, with the next major version.

| Rubygem       |   | Elasticsearch |
|:-------------:|:-:| :-----------: |
| 0.1           | → | 1.x           |
| 2.x           | → | 2.x           |
| 5.x           | → | 5.x           |
| master        | → | master        |

## Installation

Install the package from [Rubygems](https://rubygems.org):

    gem install elasticsearch-persistence

To use an unreleased version, either add it to your `Gemfile` for [Bundler](http://bundler.io):

    gem 'elasticsearch-persistence', git: 'git://github.com/elastic/elasticsearch-rails.git', branch: '5.x'

or install it from a source code checkout:

    git clone https://github.com/elastic/elasticsearch-rails.git
    cd elasticsearch-rails/elasticsearch-persistence
    bundle install
    rake install

## Usage

The library provides two different patterns for adding persistence to your Ruby objects:

* [Repository Pattern](#the-repository-pattern)

### The Repository Pattern

The `Elasticsearch::Persistence::Repository` module provides an implementation of the
[repository pattern](http://martinfowler.com/eaaCatalog/repository.html) and allows
to save, delete, find and search objects stored in Elasticsearch, as well as configure
mappings and settings for the index. It's an unobtrusive and decoupled way of adding
persistence to your Ruby objects.

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

The repository module provides a number of features and facilities to configure and customize the behavior:

* Configuring the Elasticsearch [client](https://github.com/elastic/elasticsearch-ruby#usage) being used
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

  # Specify the class to initialize when deserializing documents
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

The repository uses the standard Elasticsearch [client](https://github.com/elastic/elasticsearch-ruby#usage),
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

The ActiveRecord pattern has been deprecated as of version 6.0.0 of this gem. Please use the
[Repository Pattern](#the-repository-pattern) instead.

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
