require 'spec_helper'

describe 'Elasticsearch::Model::Adapter::ActiveRecord Dynamic Index naming' do

  before do
    ArticleWithDynamicIndexName.counter = 0
  end

  it 'exavlues the index_name value' do
    expect(ArticleWithDynamicIndexName.index_name).to eq('articles-1')
  end

  it 'revaluates the index name with each call' do
    expect(ArticleWithDynamicIndexName.index_name).to eq('articles-1')
    expect(ArticleWithDynamicIndexName.index_name).to eq('articles-2')
    expect(ArticleWithDynamicIndexName.index_name).to eq('articles-3')
  end
end
