require 'test_helper'

require 'rails/railtie'
require 'lograge'

require 'elasticsearch/rails/lograge'

class Elasticsearch::Rails::LogrageTest < Test::Unit::TestCase
  context "Lograge integration" do
    setup do
      Elasticsearch::Rails::Lograge::Railtie.run_initializers
    end

    should "customize the Lograge configuration" do
      assert_not_nil Elasticsearch::Rails::Lograge::Railtie.initializers
                       .select { |i| i.name == 'elasticsearch.lograge' }
                       .first
    end
  end
end
