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

describe Elasticsearch::Persistence::Repository do

  describe '#create' do

    before(:all) do
      class RepositoryWithoutDSL
        include Elasticsearch::Persistence::Repository
      end
    end

    after(:all) do
      if defined?(RepositoryWithoutDSL)
        Object.send(:remove_const, RepositoryWithoutDSL.name)
      end
    end

    it 'creates a repository object' do
      expect(RepositoryWithoutDSL.create).to be_a(RepositoryWithoutDSL)
    end

    context 'when options are provided' do

      let(:repository) do
        RepositoryWithoutDSL.create(document_type: 'note')
      end

      it 'sets the options on the instance' do
        expect(repository.document_type).to eq('note')
      end
    end

    context 'when a block is passed' do

      let(:repository) do
        RepositoryWithoutDSL.create(document_type: 'note') do
          mapping dynamic: 'strict' do
            indexes :foo
          end
        end
      end

      it 'executes the block on the instance' do
        expect(repository.mapping.to_hash).to eq(note: { dynamic: 'strict', properties: { foo: { type: 'text' } } })
      end

      context 'when options are provided in the args and set in the block' do

        let(:repository) do
          RepositoryWithoutDSL.create(mapping: double('mapping', to_hash: {}), document_type: 'note') do
            mapping dynamic: 'strict' do
              indexes :foo
            end
          end
        end

        it 'uses the options from the args' do
          expect(repository.mapping.to_hash).to eq({})
        end
      end
    end
  end

  describe '#initialize' do

    before(:all) do
      class RepositoryWithoutDSL
        include Elasticsearch::Persistence::Repository
      end
    end

    after(:all) do
      if defined?(RepositoryWithoutDSL)
        Object.send(:remove_const, RepositoryWithoutDSL.name)
      end
    end

    after do
      begin; repository.delete_index!; rescue; end
    end

    context 'when options are not provided' do

      let(:repository) do
        RepositoryWithoutDSL.new
      end

      it 'sets a default client' do
        expect(repository.client).to be_a(Elasticsearch::Transport::Client)
      end

      it 'sets a default document type' do
        expect(repository.document_type).to eq('_doc')
      end

      it 'sets a default index name' do
        expect(repository.index_name).to eq('repository')
      end

      it 'does not set a klass' do
        expect(repository.klass).to be_nil
      end
    end

    context 'when options are provided' do

      let(:client) do
        Elasticsearch::Client.new
      end

      let(:repository) do
        RepositoryWithoutDSL.new(client: client, document_type: 'user', index_name: 'users', klass: Array)
      end

      it 'sets the client' do
        expect(repository.client).to be(client)
      end

      it 'sets document type' do
        expect(repository.document_type).to eq('user')
      end

      it 'sets index name' do
        expect(repository.index_name).to eq('users')
      end

      it 'sets the klass' do
        expect(repository.klass).to eq(Array)
      end
    end
  end

  context 'when the DSL module is included' do

    before(:all) do
      class RepositoryWithDSL
        include Elasticsearch::Persistence::Repository
        include Elasticsearch::Persistence::Repository::DSL

        document_type 'note'
        index_name 'notes_repo'
        klass Hash
        client DEFAULT_CLIENT

        settings number_of_shards: 1, number_of_replicas: 0 do
          mapping dynamic: 'strict' do
            indexes :foo do
              indexes :bar
            end
            indexes :baz
          end
        end
      end
    end

    after(:all) do
      if defined?(RepositoryWithDSL)
        Object.send(:remove_const, RepositoryWithDSL.name)
      end
    end

    after do
      begin; repository.delete_index; rescue; end
    end

    context '#client' do

      it 'allows the value to be set only once on the class' do
        RepositoryWithDSL.client(double('client', class: 'other_client'))
        expect(RepositoryWithDSL.client).to be(DEFAULT_CLIENT)
      end

      it 'sets the value at the class level' do
        expect(RepositoryWithDSL.client).to be(DEFAULT_CLIENT)
      end

      it 'sets the value as the default at the instance level' do
        expect(RepositoryWithDSL.new.client).to be(DEFAULT_CLIENT)
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithDSL.new(client: double('client', instance: 'other')).client.instance).to eq('other')
      end
    end

    context '#klass' do

      it 'allows the value to be set only once on the class' do
        RepositoryWithDSL.klass(Array)
        expect(RepositoryWithDSL.klass).to eq(Hash)
      end

      it 'sets the value at the class level' do
        expect(RepositoryWithDSL.klass).to eq(Hash)
      end

      it 'sets the value as the default at the instance level' do
        expect(RepositoryWithDSL.new.klass).to eq(Hash)
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithDSL.new(klass: Array).klass).to eq(Array)
      end

      context 'when nil is passed to the method' do

        before do
          RepositoryWithDSL.klass(nil)
        end

        it 'allows the value to be set only once' do
          expect(RepositoryWithDSL.klass).to eq(Hash)
        end
      end
    end

    context '#document_type' do

      it 'allows the value to be set only once on the class' do
        RepositoryWithDSL.document_type('other_note')
        expect(RepositoryWithDSL.document_type).to eq('note')
      end

      it 'sets the value at the class level' do
        expect(RepositoryWithDSL.document_type).to eq('note')
      end

      it 'sets the value as the default at the instance level' do
        expect(RepositoryWithDSL.new.document_type).to eq('note')
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithDSL.new(document_type: 'other_note').document_type).to eq('other_note')
      end
    end

    context '#index_name' do

      it 'allows the value to be set only once on the class' do
        RepositoryWithDSL.index_name('other_name')
        expect(RepositoryWithDSL.index_name).to eq('notes_repo')
      end

      it 'sets the value at the class level' do
        expect(RepositoryWithDSL.index_name).to eq('notes_repo')
      end

      it 'sets the value as the default at the instance level' do
        expect(RepositoryWithDSL.new.index_name).to eq('notes_repo')
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithDSL.new(index_name: 'other_notes_repo').index_name).to eq('other_notes_repo')
      end
    end

    describe '#create_index!' do

      context 'when the method is called on an instance' do

        let(:repository) do
          RepositoryWithDSL.new
        end

        before do
          begin; repository.delete_index!; rescue; end
          repository.create_index!
        end

        it 'creates the index' do
          expect(repository.index_exists?).to be(true)
        end
      end

      context 'when the method is called on the class' do

        it 'raises a NotImplementedError' do
          expect {
            RepositoryWithDSL.create_index!
          }.to raise_exception(NotImplementedError)
        end
      end
    end

    describe '#delete_index!' do

      context 'when the method is called on an instance' do

        let(:repository) do
          RepositoryWithDSL.new
        end

        before do
          repository.create_index!
          begin; repository.delete_index!; rescue; end
        end

        it 'deletes the index' do
          expect(repository.index_exists?).to be(false)
        end
      end

      context 'when the method is called on the class' do

        it 'raises a NotImplementedError' do
          expect {
            RepositoryWithDSL.delete_index!
          }.to raise_exception(NotImplementedError)
        end
      end
    end

    describe '#refresh_index!' do

      context 'when the method is called on an instance' do

        let(:repository) do
          RepositoryWithDSL.new
        end

        before do
          repository.create_index!
        end

        it 'refreshes the index' do
          expect(repository.refresh_index!['_shards']).to be_a(Hash)
        end
      end

      context 'when the method is called on the class' do

        it 'raises a NotImplementedError' do
          expect {
            RepositoryWithDSL.refresh_index!
          }.to raise_exception(NotImplementedError)
        end
      end
    end

    describe '#index_exists?' do

      context 'when the method is called on an instance' do

        let(:repository) do
          RepositoryWithDSL.new
        end

        before do
          repository.create_index!
        end

        it 'determines if the index exists' do
          expect(repository.index_exists?).to be(true)
        end

        context 'when arguments are passed in' do

          it 'passes the arguments to the request' do
            expect(repository.index_exists?(index: 'other')).to be(false)
          end
        end
      end

      context 'when the method is called on the class' do

        it 'raises a NotImplementedError' do
          expect {
            RepositoryWithDSL.index_exists?
          }.to raise_exception(NotImplementedError)
        end
      end
    end

    describe '#mapping' do

      let(:expected_mapping) do
        { note: { dynamic: 'strict',
                  properties: { foo: { type: 'object',
                                       properties: { bar: { type: 'text' } } },
                                baz: { type: 'text' } }
                }
        }
      end

      it 'sets the value at the class level' do
        expect(RepositoryWithDSL.mapping.to_hash).to eq(expected_mapping)
      end

      it 'sets the value as the default at the instance level' do
        expect(RepositoryWithDSL.new.mapping.to_hash).to eq(expected_mapping)
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithDSL.new(mapping: double('mapping', to_hash: { note: {} })).mapping.to_hash).to eq(note: {})
      end

      context 'when the instance has a different document type' do

        let(:expected_mapping) do
          { other_note: { dynamic: 'strict',
                          properties: { foo: { type: 'object',
                                               properties: { bar: { type: 'text' } } },
                                        baz: { type: 'text' } }
                        }
          }
        end

        it 'updates the mapping to use the document type' do
          expect(RepositoryWithDSL.new(document_type: 'other_note').mapping.to_hash).to eq(expected_mapping)
        end
      end
    end

    describe '#settings' do

      it 'sets the value at the class level' do
        expect(RepositoryWithDSL.settings.to_hash).to eq(number_of_shards: 1, number_of_replicas: 0)
      end

      it 'sets the value as the default at the instance level' do
        expect(RepositoryWithDSL.new.settings.to_hash).to eq(number_of_shards: 1, number_of_replicas: 0)
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithDSL.new(settings: { number_of_shards: 3 }).settings.to_hash).to eq({number_of_shards: 3})
      end
    end
  end

  context 'when the DSL module is not included' do

    before(:all) do
      class RepositoryWithoutDSL
        include Elasticsearch::Persistence::Repository
      end
    end

    after(:all) do
      if defined?(RepositoryWithoutDSL)
        Object.send(:remove_const, RepositoryWithoutDSL.name)
      end
    end

    context '#client' do

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.client
        }.to raise_exception(NoMethodError)
      end

      it 'sets a default on the instance' do
        expect(RepositoryWithoutDSL.new.client).to be_a(Elasticsearch::Transport::Client)
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithoutDSL.new(client: double('client', object_id: 123)).client.object_id).to eq(123)
      end
    end

    context '#klass' do

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.klass
        }.to raise_exception(NoMethodError)
      end

      it 'does not set a default on an instance' do
        expect(RepositoryWithoutDSL.new.klass).to be_nil
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithoutDSL.new(klass: Array).klass).to eq(Array)
      end
    end

    context '#document_type' do

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.document_type
        }.to raise_exception(NoMethodError)
      end

      it 'sets a default on the instance' do
        expect(RepositoryWithoutDSL.new.document_type).to eq('_doc')
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithoutDSL.new(document_type: 'notes').document_type).to eq('notes')
      end
    end

    context '#index_name' do

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.index_name
        }.to raise_exception(NoMethodError)
      end

      it 'sets a default on the instance' do
        expect(RepositoryWithoutDSL.new.index_name).to eq('repository')
      end

      it 'allows the value to be overridden with options on the instance' do
        expect(RepositoryWithoutDSL.new(index_name: 'notes_repository').index_name).to eq('notes_repository')
      end
    end

    describe '#create_index!' do

      let(:repository) do
        RepositoryWithoutDSL.new(client: DEFAULT_CLIENT)
      end

      after do
        begin; repository.delete_index!; rescue; end
      end

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.create_index!
        }.to raise_exception(NoMethodError)
      end

      it 'creates an index' do
        repository.create_index!
        expect(repository.index_exists?).to eq(true)
      end
    end

    describe '#delete_index!' do

      let(:repository) do
        RepositoryWithoutDSL.new(client: DEFAULT_CLIENT)
      end

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.delete_index!
        }.to raise_exception(NoMethodError)
      end

      it 'deletes an index' do
        repository.create_index!
        repository.delete_index!
        expect(repository.index_exists?).to eq(false)
      end
    end

    describe '#refresh_index!' do

      let(:repository) do
        RepositoryWithoutDSL.new(client: DEFAULT_CLIENT)
      end

      after do
        begin; repository.delete_index!; rescue; end
      end

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.refresh_index!
        }.to raise_exception(NoMethodError)
      end

      it 'refreshes an index' do
        repository.create_index!
        expect(repository.refresh_index!['_shards']).to be_a(Hash)
      end
    end

    describe '#index_exists?' do

      let(:repository) do
        RepositoryWithoutDSL.new(client: DEFAULT_CLIENT)
      end

      after do
        begin; repository.delete_index!; rescue; end
      end

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.index_exists?
        }.to raise_exception(NoMethodError)
      end

      it 'returns whether the index exists' do
        repository.create_index!
        expect(repository.index_exists?).to be(true)
      end
    end

    describe '#mapping' do

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.mapping
        }.to raise_exception(NoMethodError)
      end

      it 'sets a default on an instance' do
        expect(RepositoryWithoutDSL.new.mapping.to_hash).to eq(_doc: { properties: {} })
      end

      it 'allows the mapping to be set as an option' do
        expect(RepositoryWithoutDSL.new(mapping: double('mapping', to_hash: { note: {} })).mapping.to_hash).to eq(note: {})
      end

      context 'when a block is passed to the create method' do

        let(:expected_mapping) do
          { note: { dynamic: 'strict',
                    properties: { foo: { type: 'object',
                                         properties: { bar: { type: 'text' } } },
                                  baz: { type: 'text' } }
            }
          }
        end

        let(:repository) do
          RepositoryWithoutDSL.create(document_type: 'note') do
            mapping dynamic: 'strict' do
              indexes :foo do
                indexes :bar
              end
              indexes :baz
            end
          end
        end

        it 'allows the mapping to be set in the block' do
          expect(repository.mapping.to_hash).to eq(expected_mapping)
        end

        context 'when the mapping is set in the options' do

          let(:repository) do
            RepositoryWithoutDSL.create(mapping: double('mapping', to_hash: { note: {} })) do
              mapping dynamic: 'strict' do
                indexes :foo do
                  indexes :bar
                end
                indexes :baz
              end
            end
          end

          it 'uses the mapping from the options' do
            expect(repository.mapping.to_hash).to eq(note: {})
          end
        end
      end
    end

    describe '#settings' do

      it 'does not define the method at the class level' do
        expect {
          RepositoryWithoutDSL.settings
        }.to raise_exception(NoMethodError)
      end

      it 'sets a default on an instance' do
        expect(RepositoryWithoutDSL.new.settings.to_hash).to eq({})
      end

      it 'allows the settings to be set as an option' do
        expect(RepositoryWithoutDSL.new(settings: double('settings', to_hash: {})).settings.to_hash).to eq({})
      end

      context 'when a block is passed to the #create method' do

        let(:repository) do
          RepositoryWithoutDSL.create(document_type: 'note') do
            settings number_of_shards: 1, number_of_replicas: 0
          end
        end

        it 'allows the settings to be set with a block' do
          expect(repository.settings.to_hash).to eq(number_of_shards: 1, number_of_replicas: 0)
        end

        context 'when a mapping is set in the block as well' do

          let(:expected_mapping) do
            { note: { dynamic: 'strict',
                      properties: { foo: { type: 'object',
                                           properties: { bar: { type: 'text' } } },
                                    baz: { type: 'text' } }
                    }
            }
          end

          let(:repository) do
            RepositoryWithoutDSL.create(document_type: 'note') do
              settings number_of_shards: 1, number_of_replicas: 0 do
                mapping dynamic: 'strict' do
                  indexes :foo do
                    indexes :bar
                  end
                  indexes :baz
                end
              end
            end
          end

          it 'allows the settings to be set with a block' do
            expect(repository.settings.to_hash).to eq(number_of_shards: 1, number_of_replicas: 0)
          end

          it 'allows the mapping to be set with a block' do
            expect(repository.mappings.to_hash).to eq(expected_mapping)
          end
        end
      end
    end
  end
end
