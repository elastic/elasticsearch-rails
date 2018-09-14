require 'pry-nav'
require 'kaminari'
require 'will_paginate'
require 'will_paginate/collection'
require 'elasticsearch/model'
require 'hashie/version'
require 'active_model'
require 'yaml'

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end
