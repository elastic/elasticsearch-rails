require 'pry-nav'
require 'kaminari'
require 'will_paginate'
require 'will_paginate/collection'
require 'elasticsearch/model'

RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color = true
end
