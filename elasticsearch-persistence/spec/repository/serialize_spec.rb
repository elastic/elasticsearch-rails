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

describe Elasticsearch::Persistence::Repository::Serialize do

  let(:repository) do
    DEFAULT_REPOSITORY
  end

  describe '#serialize' do

    before do
      class MyDocument
        def to_hash
          { a: 1 }
        end
      end
    end

    it 'calls #to_hash on the object' do
      expect(repository.serialize(MyDocument.new)).to eq(a: 1)
    end
  end

  describe '#deserialize' do

    context 'when klass is defined on the Repository' do

      let(:repository) do
        require 'set'
        MyTestRepository.new(klass: Set)
      end

      it 'instantiates an object of the klass' do
        expect(repository.deserialize('_source' => { a: 1 })).to be_a(Set)
      end

      it 'uses the source field to instantiate the object' do
        expect(repository.deserialize('_source' => { a: 1 })).to eq(Set.new({ a: 1}))
      end
    end

    context 'when klass is not defined on the Repository' do

      it 'returns the raw Hash' do
        expect(repository.deserialize('_source' => { a: 1 })).to be_a(Hash)
      end

      it 'uses the source field to instantiate the object' do
        expect(repository.deserialize('_source' => { a: 1 })).to eq(a: 1)
      end
    end
  end
end
