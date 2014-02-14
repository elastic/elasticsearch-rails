# Prevent `MyModel.inspect` failing with `ActiveRecord::ConnectionNotEstablished`
# (triggered by elasticsearch-model/lib/elasticsearch/model.rb:79:in `included')
#
ActiveRecord::Base.instance_eval do
  class << self
    def inspect_with_rescue
      inspect_without_rescue
    rescue ActiveRecord::ConnectionNotEstablished
      "#{self}(no database connection)"
    end

    alias_method_chain :inspect, :rescue
  end
end if defined?(ActiveRecord) && ActiveRecord::VERSION::STRING < '4'
