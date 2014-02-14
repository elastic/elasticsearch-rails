require 'test_helper'

begin
  require 'mongoid'
  session = Moped::Connection.new("localhost", 27017, 0.5)
  session.connect
  ENV["MONGODB_AVAILABLE"] = 'yes'
rescue LoadError, Moped::Errors::ConnectionFailure => e
  $stderr.puts "MongoDB not installed or running: #{e}"
end

if ENV["MONGODB_AVAILABLE"]
  $stderr.puts "Mongoid #{Mongoid::VERSION}", '-'*80

  logger = ::Logger.new($stderr)
  logger.formatter = lambda { |s, d, p, m| " #{m.ansi(:faint, :cyan)}\n" }
  logger.level = ::Logger::DEBUG

  Mongoid.logger = logger unless ENV['QUIET']
  Moped.logger   = logger unless ENV['QUIET']

  Mongoid.connect_to 'mongoid_articles'

  module Elasticsearch
    module Model
      class MongoidBasicIntegrationTest < Elasticsearch::Test::IntegrationTestCase

        class ::MongoidArticle
          include Mongoid::Document
          include Elasticsearch::Model
          include Elasticsearch::Model::Callbacks

          field :id, type: String
          field :title, type: String
          attr_accessible :title if respond_to? :attr_accessible

          settings index: { number_of_shards: 1, number_of_replicas: 0 } do
            mapping do
              indexes :title,      type: 'string', analyzer: 'snowball'
              indexes :created_at, type: 'date'
            end
          end

          def as_indexed_json(options={})
            as_json(except: [:id, :_id])
          end
        end

        context "Mongoid integration" do
          setup do
            Elasticsearch::Model::Adapter.register \
              Elasticsearch::Model::Adapter::Mongoid,
              lambda { |klass| !!defined?(::Mongoid::Document) && klass.ancestors.include?(::Mongoid::Document) }

            MongoidArticle.__elasticsearch__.create_index! force: true

            MongoidArticle.delete_all

            MongoidArticle.create! title: 'Test'
            MongoidArticle.create! title: 'Testing Coding'
            MongoidArticle.create! title: 'Coding'

            MongoidArticle.__elasticsearch__.refresh_index!
          end

          should "index and find a document" do
            response = MongoidArticle.search('title:test')

            assert response.any?

            assert_equal 2, response.results.size
            assert_equal 2, response.records.size

            assert_instance_of Elasticsearch::Model::Response::Result, response.results.first
            assert_instance_of MongoidArticle, response.records.first

            assert_equal 'Test', response.results.first.title
            assert_equal 'Test', response.records.first.title
          end

          should "iterate over results" do
            response = MongoidArticle.search('title:test')

            assert_equal ['Test', 'Testing Coding'], response.results.map(&:title)
            assert_equal ['Test', 'Testing Coding'], response.records.map(&:title)
          end

          should "access results from records" do
            response = MongoidArticle.search('title:test')

            response.records.each_with_hit do |r, h|
              assert_not_nil h._score
              assert_not_nil h._source.title
            end
          end

          should "remove document from index on destroy" do
            article = MongoidArticle.first

            article.destroy
            assert_equal 2, MongoidArticle.count

            MongoidArticle.__elasticsearch__.refresh_index!

            response = MongoidArticle.search 'title:test'

            assert_equal 1, response.results.size
            assert_equal 1, response.records.size
          end

          should "index updates to the document" do
            article = MongoidArticle.first

            article.title = 'Writing'
            article.save

            MongoidArticle.__elasticsearch__.refresh_index!

            response = MongoidArticle.search 'title:write'

            assert_equal 1, response.results.size
            assert_equal 1, response.records.size
          end

          should "return results for a DSL search" do
            response = MongoidArticle.search query: { match: { title: { query: 'test' } } }

            assert_equal 2, response.results.size
            assert_equal 2, response.records.size
          end

          should "return a paged collection" do
            response = MongoidArticle.search query: { match: { title: { query: 'test' } } },
                                      size: 2,
                                      from: 1

            assert_equal 1, response.results.size
            assert_equal 1, response.records.size

            assert_equal 'Testing Coding', response.results.first.title
            assert_equal 'Testing Coding', response.records.first.title
          end


          context "importing" do
            setup do
              MongoidArticle.delete_all
              97.times { |i| MongoidArticle.create! title: "Test #{i}" }
              MongoidArticle.__elasticsearch__.create_index! force: true
            end

            should "import all the documents" do
              assert_equal 97, MongoidArticle.count

              MongoidArticle.__elasticsearch__.refresh_index!
              assert_equal 0, MongoidArticle.search('*').results.total

              batches = 0
              errors  = MongoidArticle.import(batch_size: 10) do |response|
                batches += 1
              end

              assert_equal 0, errors
              assert_equal 10, batches

              MongoidArticle.__elasticsearch__.refresh_index!
              assert_equal 97, MongoidArticle.search('*').results.total

              response = MongoidArticle.search('test')
              assert response.results.any?, "Search has not returned results: #{response.to_a}"
            end
          end
        end

      end
    end
  end

end
