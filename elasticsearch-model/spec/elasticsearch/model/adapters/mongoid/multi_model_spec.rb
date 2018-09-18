require 'spec_helper'

describe 'Elasticsearch::Model::Adapter::ActiveRecord Multimodel', if: test_mongoid? do

  before(:all) do
    connect_mongoid('mongoid_test')

    begin
      ActiveRecord::Schema.define(:version => 1) do
      create_table Episode.table_name do |t|
        t.string :name
        t.datetime :created_at, :default => 'NOW()'
      end
      end
    rescue
    end
  end

  before do
    clear_tables(Episode, Image)
    Episode.__elasticsearch__.create_index! force: true
    Episode.create name: "TheEpisode"
    Episode.create name: "A great Episode"
    Episode.create name: "The greatest Episode"
    Episode.__elasticsearch__.refresh_index!

    Image.__elasticsearch__.create_index! force: true
    Image.create! name: "The Image"
    Image.create! name: "A great Image"
    Image.create! name: "The greatest Image"
    Image.__elasticsearch__.refresh_index!
    Image.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'
  end

  after do
    [Episode, Image].each do |model|
      model.__elasticsearch__.client.delete_by_query(index: model.index_name, q: '*')
      model.delete_all
      model.__elasticsearch__.refresh_index!
    end
  end

  context 'when the search is across multimodels with different adapters' do

    let(:search_result) do
      Elasticsearch::Model.search(%q<"greatest Episode" OR "greatest Image"^2>, [Episode, Image])
    end

    it 'executes the search across models' do
      expect(search_result.results.size).to eq(2)
      expect(search_result.records.size).to eq(2)
    end

    it 'returns the correct type of model instance' do
      expect(search_result.records[0]).to be_a(Image)
      expect(search_result.records[1]).to be_a(Episode)
    end

    it 'creates the model instances with the correct attributes' do
      expect(search_result.results[0].name).to eq('The greatest Image')
      expect(search_result.records[0].name).to eq('The greatest Image')
      expect(search_result.results[1].name).to eq('The greatest Episode')
      expect(search_result.records[1].name).to eq('The greatest Episode')
    end
  end
end
