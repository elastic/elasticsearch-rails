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

describe Elasticsearch::Persistence::Repository::Find do

  after do
    begin; repository.delete_index!; rescue; end
  end

  let(:repository) do
    DEFAULT_REPOSITORY
  end

  describe '#exists?' do

    context 'when the document exists' do

      let(:id) do
        repository.save(a: 1)['_id']
      end

      it 'returns true' do
        expect(repository.exists?(id)).to be(true)
      end
    end

    context 'when the document does not exist' do

      it 'returns false' do
        expect(repository.exists?('1')).to be(false)
      end
    end

    context 'when options are provided' do

      let(:id) do
        repository.save(a: 1)['_id']
      end

      it 'applies the options' do
        expect(repository.exists?(id, type: 'other_type')).to be(false)
      end
    end
  end

  describe '#find' do

    context 'when options are not provided' do

      context 'when a single id is provided' do

        let!(:id) do
          repository.save(a: 1)['_id']
        end

        it 'retrieves the document' do
          expect(repository.find(id)).to eq('a' => 1)
        end
      end

      context 'when an array of ids is provided' do

        let!(:ids) do
          3.times.collect do |i|
            repository.save(a: i)['_id']
          end
        end

        it 'retrieves the documents' do
          expect(repository.find(ids)).to eq([{ 'a' =>0 },
                                              { 'a' => 1 },
                                              { 'a' => 2 }])
        end

        context 'when some documents are found and some are not' do

          before do
            ids[1] = 22
            ids
          end

          it 'returns nil in the result list for the documents not found' do
            expect(repository.find(ids)).to eq([{ 'a' =>0 },
                                                 nil,
                                                 { 'a' => 2 }])
          end
        end
      end

      context 'when multiple ids are provided' do

        let!(:ids) do
          3.times.collect do |i|
            repository.save(a: i)['_id']
          end
        end

        it 'retrieves the documents' do
          expect(repository.find(*ids)).to eq([{ 'a' =>0 },
                                              { 'a' => 1 },
                                              { 'a' => 2 }])
        end
      end

      context 'when the document cannot be found' do

        before do
          begin; repository.create_index!; rescue; end
        end

        it 'raises a DocumentNotFound exception' do
          expect {
            repository.find(1)
          }.to raise_exception(Elasticsearch::Persistence::Repository::DocumentNotFound)
        end
      end
    end

    context 'when options are provided' do

      context 'when a single id is passed' do

        let!(:id) do
          repository.save(a: 1)['_id']
        end

        it 'applies the options' do
          expect {
            repository.find(id, type: 'none')
          }.to raise_exception(Elasticsearch::Persistence::Repository::DocumentNotFound)
        end
      end

      context 'when an array of ids is passed' do

        let!(:ids) do
          3.times.collect do |i|
            repository.save(a: i)['_id']
          end
        end

        it 'applies the options' do
          expect(repository.find(ids, type: 'none')).to eq([nil, nil, nil])
        end
      end

      context 'when multiple ids are passed' do

        let!(:ids) do
          3.times.collect do |i|
            repository.save(a: i)['_id']
          end
        end

        it 'applies the options' do
          expect(repository.find(*ids, type: 'none')).to eq([nil, nil, nil])
        end
      end
    end

    context 'when a document_type is defined on the class' do

      let(:repository) do
        MyTestRepository.new(document_type:'other_type', client: DEFAULT_CLIENT, index_name: 'test')
      end

      let!(:ids) do
        3.times.collect do |i|
          repository.save(a: i)['_id']
        end
      end

      it 'uses the document type in the query' do
        expect(repository.find(ids)).to eq([{ 'a' =>0 },
                                            { 'a' => 1 },
                                            { 'a' => 2 }])
      end
    end
  end
end
