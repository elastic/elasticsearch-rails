require 'test_helper'

class Elasticsearch::Persistence::RepositoryModuleTest < Test::Unit::TestCase
  context "The repository module" do

    class DummyModel
      def initialize(attributes={})
        @attributes = attributes
      end

      def to_hash
        @attributes
      end

      def inspect
        "<Note #{@attributes.inspect}>"
      end
    end

    setup do
      class DummyRepository
        include Elasticsearch::Persistence::Repository
      end
    end

    teardown do
      Elasticsearch::Persistence::RepositoryModuleTest.__send__ :remove_const, :DummyRepository
    end

    context "when included" do
      should "set up the gateway for the class and instance" do
        assert_respond_to DummyRepository,     :gateway
        assert_respond_to DummyRepository.new, :gateway

        assert_instance_of Elasticsearch::Persistence::Repository::Class, DummyRepository.gateway
        assert_instance_of Elasticsearch::Persistence::Repository::Class, DummyRepository.new.gateway
      end

      should "proxy repository methods from the class to the gateway" do
        class DummyRepository
          include Elasticsearch::Persistence::Repository

          index :foobar
          klass DummyModel
          type  :my_dummy_model
          mapping { indexes :title, analyzer: 'snowball' }
        end

        repository = DummyRepository.new

        assert_equal :foobar,         DummyRepository.index
        assert_equal DummyModel,      DummyRepository.klass
        assert_equal :my_dummy_model, DummyRepository.type
        assert_equal 'snowball', DummyRepository.mappings.to_hash[:my_dummy_model][:properties][:title][:analyzer]

        assert_equal :foobar,         repository.index
        assert_equal DummyModel,      repository.klass
        assert_equal :my_dummy_model, repository.type
        assert_equal 'snowball', repository.mappings.to_hash[:my_dummy_model][:properties][:title][:analyzer]
      end

      should "correctly delegate to the gateway" do
        repository = DummyRepository.new
        assert_instance_of Method, repository.method(:index)
      end

      should "proxy repository methods from the instance to the gateway" do
        class DummyRepository
          include Elasticsearch::Persistence::Repository
        end

        repository = DummyRepository.new
        repository.index :foobar
        repository.klass DummyModel
        repository.type  :my_dummy_model
        repository.mapping { indexes :title, analyzer: 'snowball' }

        assert_equal :foobar,         DummyRepository.index
        assert_equal DummyModel,      DummyRepository.klass
        assert_equal :my_dummy_model, DummyRepository.type
        assert_equal 'snowball', DummyRepository.mappings.to_hash[:my_dummy_model][:properties][:title][:analyzer]

        assert_equal :foobar,         repository.index
        assert_equal DummyModel,      repository.klass
        assert_equal :my_dummy_model, repository.type
        assert_equal 'snowball', repository.mappings.to_hash[:my_dummy_model][:properties][:title][:analyzer]
      end

      should "allow to define gateway methods in the class definition via block passed to the gateway method" do
        class DummyRepositoryWithGatewaySerialize
          include Elasticsearch::Persistence::Repository

          gateway do
            def serialize(document)
              'FAKE!'
            end
          end
        end

        repository = DummyRepositoryWithGatewaySerialize.new
        repository.client.transport.logger = Logger.new(STDERR)

        client = mock
        client.expects(:index).with do |arguments|
          assert_equal('xxx',   arguments[:id])
          assert_equal('FAKE!', arguments[:body])
          true
        end
        repository.gateway.expects(:client).returns(client)

        repository.gateway.expects(:__get_id_from_document).returns('xxx')

        repository.save( id: '123', foo: 'bar' )
      end
    end

    should "allow to define gateway methods in the class definition via regular method definition" do
      class DummyRepositoryWithDirectSerialize
        include Elasticsearch::Persistence::Repository

        def serialize(document)
          'FAKE IN CLASS!'
        end
      end

      repository = DummyRepositoryWithDirectSerialize.new
      repository.client.transport.logger = Logger.new(STDERR)

      client = mock
      client.expects(:index).with do |arguments|
        assert_equal('xxx',   arguments[:id])
        assert_equal('FAKE IN CLASS!', arguments[:body])
        true
      end
      repository.gateway.expects(:client).returns(client)

      repository.gateway.expects(:__get_id_from_document).returns('xxx')

      repository.save( id: '123', foo: 'bar' )
    end

    should "configure the index name in the shortcut initializer" do
      assert_equal 'repository', Elasticsearch::Persistence::Repository.new.index_name
    end
  end
end
