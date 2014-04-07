#\ --port 3000 --server thin

require File.expand_path('../application', __FILE__)

map '/' do
  run Application
end
