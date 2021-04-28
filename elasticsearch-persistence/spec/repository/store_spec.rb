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

require 'spec_helper'

describe Elasticsearch::Persistence::Repository::Store do

  let(:repository) do
    DEFAULT_REPOSITORY
  end

  after do
    begin; repository.delete_index!; rescue; end
  end

  describe '#save' do

    let(:document) do
      { a: 1 }
    end

    let(:response) do
      repository.save(document)
    end

    it 'saves the document' do
      expect(repository.find(response['_id'])).to eq('a' => 1)
    end

    context 'when the repository defines a custom serialize method' do

      before do
        class OtherNoteRepository
          include Elasticsearch::Persistence::Repository
          def serialize(document)
            { b: 1 }
          end
        end
      end

      after do
        if defined?(OtherNoteRepository)
          Object.send(:remove_const, OtherNoteRepository.name)
        end
      end

      let(:repository) do
        OtherNoteRepository.new(client: DEFAULT_CLIENT)
      end

      let(:response) do
        repository.save(document)
      end

      it 'saves the document' do
        expect(repository.find(response['_id'])).to eq('b' => 1)
      end
    end

    context 'when options are provided' do

      let!(:response) do
        repository.save(document, type: 'other_note')
      end

      it 'saves the document using the options' do
        expect {
          repository.find(response['_id'])
        }.to raise_exception(Elasticsearch::Persistence::Repository::DocumentNotFound)
        expect(repository.find(response['_id'], type: 'other_note')).to eq('a' => 1)
      end
    end
  end

  describe '#update' do

    before(:all) do
      class Note
        def to_hash
          { text: 'testing', views: 0 }
        end
      end
    end

    after(:all) do
      if defined?(Note)
        Object.send(:remove_const, :Note)
      end
    end

    context 'when the document exists' do

      let!(:id) do
        repository.save(Note.new)['_id']
      end

      context 'when an id is provided' do

        context 'when a doc is specified in the options' do

          before do
            repository.update(id, doc: { text: 'testing_2' })
          end

          it 'updates using the doc parameter' do
            expect(repository.find(id)).to eq('text' => 'testing_2', 'views' => 0)
          end
        end

        context 'when a script is specified in the options' do

          before do
            repository.update(id, script: { inline: 'ctx._source.views += 1' })
          end

          it 'updates using the script parameter' do
            expect(repository.find(id)).to eq('text' => 'testing', 'views' => 1)
          end
        end

        context 'when params are specified in the options' do

          before do
            repository.update(id, script: { inline: 'ctx._source.views += params.count',
                                            params: { count: 2 } })
          end

          it 'updates using the script parameter' do
            expect(repository.find(id)).to eq('text' => 'testing', 'views' => 2)
          end
        end

        context 'when upsert is specified in the options' do

          before do
            repository.update(id, script: { inline: 'ctx._source.views += 1' },
                                  upsert: { text: 'testing_2' })
          end

          it 'executes the script' do
            expect(repository.find(id)).to eq('text' => 'testing', 'views' => 1)
          end
        end

        context 'when doc_as_upsert is specified in the options' do

          before do
            repository.update(id, doc: { text: 'testing_2' },
                                  doc_as_upsert: true)
          end

          it 'performs an upsert' do
            expect(repository.find(id)).to eq('text' => 'testing_2', 'views' => 0)
          end
        end
      end

      context 'when a document is provided as the query criteria' do

        context 'when no options are provided' do

          before do
            repository.update(id: id, text: 'testing_2')
          end

          it 'updates using the id and the document as the doc parameter' do
            expect(repository.find(id)).to eq('text' => 'testing_2', 'views' => 0)
          end
        end

        context 'when options are provided' do

          context 'when a doc is specified in the options' do

            before do
              repository.update({ id: id, text: 'testing' }, doc: { text: 'testing_2' })
            end

            it 'updates using the id and the doc in the options' do
              expect(repository.find(id)).to eq('text' => 'testing_2', 'views' => 0)
            end
          end

          context 'when a script is specified in the options' do

            before do
              repository.update({ id: id, text: 'testing' },
                                script: { inline: 'ctx._source.views += 1' })
            end

            it 'updates using the id and script from the options' do
              expect(repository.find(id)).to eq('text' => 'testing', 'views' => 1)
            end
          end

          context 'when params are specified in the options' do

            before do
              repository.update({ id: id, text: 'testing' },
                                script: { inline: 'ctx._source.views += params.count',
                                          params: { count: 2 } })
            end

            it 'updates using the id and script and params from the options' do
              expect(repository.find(id)).to eq('text' => 'testing', 'views' => 2)
            end
          end

          context 'when upsert is specified in the options' do

            before do
              repository.update({ id: id, text: 'testing_2' },
                                doc_as_upsert: true)
            end

            it 'updates using the id and script and params from the options' do
              expect(repository.find(id)).to eq('text' => 'testing_2', 'views' => 0)
            end
          end
        end
      end
    end

    context 'when the document does not exist' do

      context 'when an id is provided 'do

        it 'raises an exception' do
          expect {
            repository.update(1, doc: { text: 'testing_2' })
          }.to raise_exception(Elasticsearch::Transport::Transport::Errors::NotFound)
        end

        context 'when upsert is provided' do

          before do
            repository.update(1, doc: { text: 'testing' }, doc_as_upsert: true)
          end

          it 'upserts the document' do
            expect(repository.find(1)).to eq('text' => 'testing')
          end
        end
      end

      context 'when a document is provided' do

        it 'raises an exception' do
          expect {
            repository.update(id: 1, text: 'testing_2')
          }.to raise_exception(Elasticsearch::Transport::Transport::Errors::NotFound)
        end

        context 'when upsert is provided' do

          before do
            repository.update({ id: 1, text: 'testing' }, doc_as_upsert: true)
          end

          it 'upserts the document' do
            expect(repository.find(1)).to eq('text' => 'testing')
          end
        end
      end
    end
  end

  describe '#delete' do

    before(:all) do
      class Note
        def to_hash
          { text: 'testing', views: 0 }
        end
      end
    end

    after(:all) do
      if defined?(Note)
        Object.send(:remove_const, :Note)
      end
    end

    context 'when the document exists' do

      let!(:id) do
        repository.save(Note.new)['_id']
      end

      context 'an id is provided' do

        before do
          repository.delete(id)
        end

        it 'deletes the document using the id' do
          expect {
            repository.find(id)
          }.to raise_exception(Elasticsearch::Persistence::Repository::DocumentNotFound)
        end
      end

      context 'when a document is provided' do

        before do
          repository.delete(id: id, text: 'testing')
        end

        it 'deletes the document using the document' do
          expect {
            repository.find(id)
          }.to raise_exception(Elasticsearch::Persistence::Repository::DocumentNotFound)
        end
      end
    end

    context 'when the document does not exist' do

      before do
        repository.create_index!(include_type_name: true)
      end

      it 'raises an exception' do
        expect {
          repository.delete(1)
        }.to raise_exception(Elasticsearch::Transport::Transport::Errors::NotFound)
      end
    end
  end
end
