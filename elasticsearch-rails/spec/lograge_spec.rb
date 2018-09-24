require 'spec_helper'
require 'action_pack'
require 'lograge'
require 'elasticsearch/rails/lograge'

describe 'ActiveSupport::Instrumentation integration' do

  before do
    Elasticsearch::Rails::Lograge::Railtie.run_initializers
  end

  it 'customizes the Lograge configuration' do
    expect(Elasticsearch::Rails::Lograge::Railtie.initializers
               .select { |i| i.name == 'elasticsearch.lograge' }
               .first).not_to be_nil
  end
end
