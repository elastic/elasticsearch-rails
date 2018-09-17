require 'spec_helper'

describe Elasticsearch::Model::HashWrapper, if: Hashie::VERSION >= '3.5.3' do

  before do
    expect(Hashie.logger).to receive(:warn).never
  end

  it 'does not print a warning for re-defined methods' do
    Elasticsearch::Model::HashWrapper.new(:foo => 'bar', :sort => true)
  end
end
