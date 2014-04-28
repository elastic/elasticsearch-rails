require 'test_helper'

require 'elasticsearch/persistence/model'
require 'elasticsearch/persistence/model/rails'

class Elasticsearch::Persistence::ModelGatewayTest < Test::Unit::TestCase
  context "The model gateway" do
    setup do
      class DummyGatewayModel
        include Elasticsearch::Persistence::Model
      end
    end

    teardown do
      Elasticsearch::Persistence::ModelGatewayTest.__send__ :remove_const, :DummyGatewayModel \
      rescue NameError; nil
    end

    should "be accessible" do
      assert_instance_of Elasticsearch::Persistence::Repository::Class, DummyGatewayModel.gateway

      $a = 0
      DummyGatewayModel.gateway { $a += 1 }
      assert_equal 1, $a

      @b = 0
      def run!; DummyGatewayModel.gateway { |g| @b += 1 }; end
      run!
      assert_equal 1, @b

      assert_equal DummyGatewayModel, DummyGatewayModel.gateway.klass
    end

    should "define common attributes" do
      d = DummyGatewayModel.new

      assert_respond_to d, :id
      assert_respond_to d, :updated_at
      assert_respond_to d, :created_at
    end

    should "allow to configure settings" do
      DummyGatewayModel.settings(number_of_shards: 1)

      assert_equal 1, DummyGatewayModel.settings.to_hash[:number_of_shards]
    end

    should "allow to configure mappings" do
      DummyGatewayModel.mapping { indexes :name, analyzer: 'snowball' }

      assert_equal 'snowball',
                   DummyGatewayModel.mapping.to_hash[:dummy_gateway_model][:properties][:name][:analyzer]
    end

    should "configure the mapping via attribute" do
      DummyGatewayModel.attribute :name, String, mapping: { analyzer: 'snowball' }

      assert_respond_to DummyGatewayModel, :name
      assert_equal 'snowball',
                   DummyGatewayModel.mapping.to_hash[:dummy_gateway_model][:properties][:name][:analyzer]
    end

    should "configure the mapping via an attribute block" do
      DummyGatewayModel.attribute :name, String do
        indexes :name, analyzer: 'custom'
      end

      assert_respond_to DummyGatewayModel, :name
      assert_equal 'custom',
                   DummyGatewayModel.mapping.to_hash[:dummy_gateway_model][:properties][:name][:analyzer]
    end

    should "remove IDs from hash when serializing" do
      assert_equal( {foo: 'bar'}, DummyGatewayModel.gateway.serialize(id: '123', foo: 'bar') )
    end

    should "set IDs from hash when deserializing" do
      assert_equal 'abc123', DummyGatewayModel.gateway.deserialize('_id' => 'abc123', '_source' => {}).id
    end

    should "set @persisted variable from hash when deserializing" do
      assert DummyGatewayModel.gateway.deserialize('_id' => 'abc123', '_source' => {}).instance_variable_get(:@persisted)
    end

  end
end
