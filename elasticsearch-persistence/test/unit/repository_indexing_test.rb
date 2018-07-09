require 'test_helper'

class Elasticsearch::Persistence::RepositoryIndexingTest < Test::Unit::TestCase
  context "The repository index methods" do
    class MyDocument; end

    setup do
      @shoulda_subject = Class.new() { include Elasticsearch::Model::Indexing::ClassMethods }.new
      @shoulda_subject.stubs(:index_name).returns('my_index')
      @shoulda_subject.stubs(:document_type).returns('my_document')
    end

    should "have the convenience index management methods" do
      %w( create_index!  delete_index! refresh_index! ).each do |method|
        assert_respond_to subject, method
      end
    end

    context "mappings" do
      should "configure the mappings for the type" do
        subject.mappings do
          indexes :title
        end

        assert_equal( {:"my_document"=>{:properties=>{:title=>{:type=>"text"}}}}, subject.mappings.to_hash )
      end
    end

    context "settings" do
      should "configure the settings for the index" do
        subject.settings foo: 'bar'
        assert_equal( {foo: 'bar'},  subject.settings.to_hash)
      end
    end

  end
end
