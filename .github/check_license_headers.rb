# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

LICENSE = File.read('./.github/license-header.txt')
files = `git ls-files | grep -E '\.rb|Rakefile|\.rake|\.erb|Gemfile|gemspec'`.split("\n")
errors = []

files.each do |file|
  unless File.read(file).include?(LICENSE)
    errors << file
    puts "#{file} doesn't contain the correct license header"
  end
end

if errors.empty?
  puts 'All checked files have the correct license header'
else
  exit 1
end
