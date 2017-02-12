require 'test_helper'

require 'hashie/version'

class Elasticsearch::Model::HashWrapperTest < Test::Unit::TestCase
  context "The HashWrapper class" do
    should "not print the warning for re-defined methods" do
      Hashie.logger.expects(:warn).never

      subject = Elasticsearch::Model::HashWrapper.new(:foo => 'bar', :sort => true)
    end if Hashie::VERSION >= '3.5.3'
  end
end
