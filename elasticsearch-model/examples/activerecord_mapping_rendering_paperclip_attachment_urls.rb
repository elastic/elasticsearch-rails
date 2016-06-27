require 'ansi'
require 'sqlite3'
require 'active_record'
require 'elasticsearch/model'
require 'paperclip'

require "paperclip/railtie"
Paperclip::Railtie.insert

ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
ActiveRecord::Base.establish_connection( adapter: 'sqlite3', database: ":memory:" )

ActiveRecord::Schema.define(version: 1) do
  create_table :properties do |t|
    t.string :title
    t.string :description
    t.timestamps
  end

  create_table :images do |t|
    t.integer :property_id
    t.string :attachment_file_name
    t.timestamps
  end
end

begin
  class Image < ActiveRecord::Base
    belongs_to :property, touch: true
    has_attached_file :attachment, styles: { thumb: '100x100>', screen: '1024x1024' }
  end
rescue => e
  puts e.inspect.ansi(:bold, :red)
  raise e
end

class Property < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  mapping do
    indexes :title
  end

  has_many :images

  def as_indexed_json(options={})
    {
      id: id,
      title: title,
      description: description,
      images: images.map do |image|
        {
          id:         image.id,
          updated_at: image.updated_at,
          attachment_file_name: image.attachment_file_name
        }
      end
    }
  end
end

class PropertesSerializer
  attr_reader :collection

  def initialize(collection:)
    @collection = collection
  end

  def as_json
    collection.map do |property|
      {
        id: property.id,
        title: property.title,
        description: property.description,
        images: property.images.map do |es_image|
          {
            thumb:  es_image_to_image(es_image).attachment.url(:thumb),
            screen: es_image_to_image(es_image).attachment.url(:screen)
          }
        end
      }
    end
  end

  # This image instance is purely for generating urls don't persist any data on it
  #
  #   :attachment_file_name  is used to generate file path
  #   :updated_at is needed to ensure proper timestamp query url is generated with Paperclip
  #
  def es_image_to_image(es_image)
    Image.new({
      id:         es_image.id,
      updated_at: es_image.updated_at,
      attachment_file_name: es_image.attachment_file_name,
    })
  end
end

Property.__elasticsearch__.client = Elasticsearch::Client.new log: true

# Create index

Property.__elasticsearch__.create_index! force: true

# Store data

Property.delete_all
Property.
  create(title: 'Cool flat in Prague', description: 'Nice view').
  tap do |property|
    Image.create!(attachment_file_name: 'prague-flat-1.jpg', property: property)
    Image.create!(attachment_file_name: 'prague-flat-2.jpg', property: property)
  end

Property.
  create(title: 'Really cool flat in Banska Bystrica').
  tap do |property|
    Image.create(attachment_file_name: 'bb.jpg', property: property)
  end

Property.
  create(title: 'Nice flat in London', description: 'Bed-Bugs included').
  tap do |property|
    Image.create(attachment_file_name: 'london-img-1.jpg', property: property)
    Image.create(attachment_file_name: 'london-img-2.jpg', property: property)
  end

Property.__elasticsearch__.refresh_index!
Property.import

sleep 2 # give ES time to reindex everyting

# Search and suggest
response_1 = Property.search(query: { match: { title: 'cool'} } )

puts "Property search:".ansi(:bold),
     response_1.to_a.map { |d| "Title: #{d.title}" }.inspect.ansi(:bold, :yellow)


puts PropertesSerializer.new(collection: response_1).as_json.inspect.ansi(:bold, :green)

# [{:id=>"1",
#   :title=>"Cool flat in Prague",
#   :description=>"Nice view",
#   :images=>
#    [{:thumb=>"/system/images/attachments/000/000/001/thumb/prague-flat-1.jpg",
#      :screen=>
#       "/system/images/attachments/000/000/001/screen/prague-flat-1.jpg"},
#     {:thumb=>"/system/images/attachments/000/000/002/thumb/prague-flat-2.jpg",
#      :screen=>
#       "/system/images/attachments/000/000/002/screen/prague-flat-2.jpg"}]},
#  {:id=>"2",
#   :title=>"Really cool flat in Banska Bystrica",
#   :description=>nil,
#   :images=>
#    [{:thumb=>"/system/images/attachments/000/000/003/thumb/bb.jpg",
#      :screen=>"/system/images/attachments/000/000/003/screen/bb.jpg"}]}]
