module Elasticsearch
  module Persistence

    module Repository
      include Elasticsearch::Persistence::Client
    end
  end
end
