
# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
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
