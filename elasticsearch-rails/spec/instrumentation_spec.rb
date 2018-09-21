require 'spec_helper'

describe 'ActiveSupport::Instrumentation integration' do

  before(:all) do
    class DummyInstrumentationModel
      extend Elasticsearch::Model::Searching::ClassMethods

      def self.index_name;    'foo'; end
      def self.document_type; 'bar'; end
    end
  end

  after(:all) do
    remove_classes(DummyInstrumentationModel)
  end

  let(:response_document) do
    { 'took' => '5ms',
      'hits' => { 'total' => 123,
                  'max_score' => 456,
                  'hits' => [] } }
  end

  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(DummyInstrumentationModel, 'foo')
  end

  let(:client) do
    double('client', search: response_document)
  end

  before do
    allow(DummyInstrumentationModel).to receive(:client).and_return(client)
    Elasticsearch::Rails::Instrumentation::Railtie.run_initializers
  end

  context 'SearchRequest#execute!' do

    it 'wraps the method with instrumentation' do
      expect(search).to respond_to(:execute_without_instrumentation!)
      expect(search).to respond_to(:execute_with_instrumentation!)
    end
  end

  context 'Model#search' do

    before do
      expect(ActiveSupport::Notifications).to receive(:instrument).with('search.elasticsearch',
                                                                        { klass: 'DummyInstrumentationModel',
                                                                          name: 'Search',
                                                                          search: { body: query,
                                                                          index: 'foo',
                                                                          type: 'bar' } }).and_return({})
    end

    let(:query) do
      { query: { match: { foo: 'bar' } } }
    end

    let(:logged_message) do
      @logger.logged(:debug).first
    end

    it 'publishes a notification' do
      expect(DummyInstrumentationModel.search(query).response).to eq({})
    end

    context 'when a message is logged', unless: defined?(RUBY_VERSION) && RUBY_VERSION > '2.2' do

      let(:query) do
        { query: { match: { moo: 'bam' } } }
      end

      it 'prints the debug information to the log' do
        expect(logged_message).to match(/DummyInstrumentationModel Search \(\d+\.\d+ms\)/)
        expect(logged_message).to match(/body\: \{query\: \{match\: \{moo\: "bam"\}\}\}\}/)
      end
    end
  end
end
