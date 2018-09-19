module MyNamespace
  class Book < ActiveRecord::Base
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    document_type 'book'

    mapping { indexes :title }
  end
end
