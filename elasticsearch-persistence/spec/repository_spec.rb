require 'spec_helper'

describe Elasticsearch::Persistence::Repository do

  before(:all) do
    class UserRepo
      include Elasticsearch::Persistence::Repository
    end
  end

  after(:all) do
    if defined?(UserRepo)
      Object.send(:remove_const, UserRepo.name)
    end
  end

  describe '#initialize' do

    context 'when options are not provided' do

      let(:repository) do
        UserRepo.new
      end

      it 'sets a default client' do
        expect(repository.client).to be_a(Elasticsearch::Transport::Client)
      end

      it 'sets default document type' do
        expect(repository.document_type).to eq('_doc')
      end

      it 'sets default index name' do
        expect(repository.index_name).to eq('repository')
      end

      it 'does not set a klass' do
        expect(repository.klass).to be_nil
      end
    end

    context 'when options are provided' do

      let(:client) do
        Elasticsearch::Transport::Client.new
      end

      let(:repository) do
        UserRepo.new(client: client, document_type: 'user', index_name: 'users', klass: Hash)
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
        expect(repository.klass).to eq(Hash)
      end
    end
  end

  describe '#with' do

    let(:repository) do
      UserRepo.new(index_name: 'users', document_type: 'user', klass: Hash)
    end

    context 'when all the options are changed' do

      let(:new_repository) do
        repository.with(index_name: 'other_users',
                        document_type: 'other_user',
                        klass: Array,
                        client: double('client)', class: Elasticsearch::Transport::Client))
      end

      it 'changes the options' do
        expect(new_repository.index_name).to eq('other_users')
        expect(new_repository.document_type).to eq('other_user')
        expect(new_repository.klass).to eq(Array)
        expect(new_repository.client.class).to eq(Elasticsearch::Transport::Client)
      end

      it 'returns a new instance of the repository class' do
        expect(new_repository).not_to be(repository)
      end

      it 'clones the options' do
        expect(new_repository.options).not_to be(repository.options)
      end
    end

    context 'when only some options are changed' do

      let(:new_repository) do
        repository.with(index_name: 'other_users')
      end

      it 'only changes the new option' do
        expect(new_repository.index_name).to eq('other_users')
        expect(new_repository.document_type).to eq('user')
        expect(new_repository.klass).to eq(Hash)
      end

      it 'returns a new instance of the repository class' do
        expect(new_repository).not_to be(repository)
      end
    end
  end

  describe 'class methods' do

    before do
      if defined?(NoteRepository)
        Object.send(:remove_const, NoteRepository.name)
      end
      class NoteRepository
        include Elasticsearch::Persistence::Repository

        document_type 'note'

        index_name 'notes_repo'

        klass Hash

        client(_class: 'client')

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

    context '#client' do

      it 'allows the value to be set only once' do
        NoteRepository.client(double('client', class: 'other_client'))
        expect(NoteRepository.client).to eq(_class: 'client')
      end

      it 'sets the value at the class level' do
        expect(NoteRepository.client).to eq(_class: 'client')
      end

      it 'sets the value as the default at the instance level' do
        expect(NoteRepository.new.client).to eq(_class: 'client')
      end

      it 'allows the value to be overwritten with options on the instance' do
        expect(NoteRepository.new(client: double('client', class: 'other_client')).client.class).to eq('other_client')
      end
    end

    context '#klass' do

      it 'allows the value to be set only once' do
        NoteRepository.klass(Array)
        expect(NoteRepository.klass).to eq(Hash)
      end

      it 'sets the value at the class level' do
        expect(NoteRepository.klass).to eq(Hash)
      end

      it 'sets the value as the default at the instance level' do
        expect(NoteRepository.new.klass).to eq(Hash)
      end

      it 'allows the value to be overwritten with options on the instance' do
        expect(NoteRepository.new(klass: Array).klass).to eq(Array)
      end

      context 'when nil is passed to the method' do

        before do
          NoteRepository.klass(nil)
        end

        it 'allows the value to be set only once' do
          expect(NoteRepository.klass).to eq(Hash)
        end
      end
    end

    context '#document_type' do

      it 'allows the value to be set only once' do
        NoteRepository.document_type('other_note')
        expect(NoteRepository.document_type).to eq('note')
      end

      it 'sets the value at the class level' do
        expect(NoteRepository.document_type).to eq('note')
      end

      it 'sets the value as the default at the instance level' do
        expect(NoteRepository.new.document_type).to eq('note')
      end

      it 'allows the value to be overwritten with options on the instance' do
        expect(NoteRepository.new(document_type: 'other_note').document_type).to eq('other_note')
      end
    end

    context '#index_name' do

      it 'allows the value to be set only once' do
        NoteRepository.index_name('other_name')
        expect(NoteRepository.index_name).to eq('notes_repo')
      end

      it 'sets the value at the class level' do
        expect(NoteRepository.index_name).to eq('notes_repo')
      end

      it 'sets the value as the default at the instance level' do
        expect(NoteRepository.new.index_name).to eq('notes_repo')
      end

      it 'allows the value to be overwritten with options on the instance' do
        expect(NoteRepository.new(index_name: 'other_notes_repo').index_name).to eq('other_notes_repo')
      end
    end

    describe '#create_index!' do

      context 'when the method is called on an instance' do

        before do
          DEFAULT_REPOSITORY.create_index!
        end

        it 'creates the index' do
          expect(DEFAULT_REPOSITORY.index_exists?).to be(true)
        end
      end
    end

    describe '#delete_index!' do

      context 'when the method is called on an instance' do

        before do
          DEFAULT_REPOSITORY.create_index!
          DEFAULT_REPOSITORY.delete_index!
        end

        it 'creates the index' do
          expect(DEFAULT_REPOSITORY.index_exists?).to be(false)
        end
      end
    end

    describe '#refresh_index!' do

      context 'when the method is called on an instance' do

        before do
          DEFAULT_REPOSITORY.create_index!
        end

        it 'creates the index' do
          expect(DEFAULT_REPOSITORY.refresh_index!['_shards']).to be_a(Hash)
        end
      end
    end

    describe '#index_exists?' do

      context 'when the method is called on an instance' do

        before do
          DEFAULT_REPOSITORY.create_index!
        end

        it 'creates the index' do
          expect(DEFAULT_REPOSITORY.index_exists?).to be(true)
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

      it 'allows the value to be set only once' do
        NoteRepository.mapping(dynamic: 'strict') { indexes :foo, type: 'long' }
        #expect(NoteRepository.mapping.to_hash).to eq('note')
      end

      it 'sets the value at the class level' do
        expect(NoteRepository.mapping.to_hash).to eq(expected_mapping)
      end

      it 'sets the value as the default at the instance level' do
        expect(NoteRepository.new.mapping.to_hash).to eq(expected_mapping)
      end

      it 'allows the value to be overwritten with options on the instance' do
        expect(NoteRepository.new(mapping: double('mapping', to_hash: { note: {} })).mapping.to_hash).to eq(note: {})
      end

      it 'allows the value to be overwritten when #with is called on an instance' do
        expect(NoteRepository.new.with(mapping: double('mapping', to_hash: { note: {} })).mapping.to_hash).to eq(note: {})
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
          expect(NoteRepository.new.with(document_type: 'other_note').mapping.to_hash).to eq(expected_mapping)
        end
      end
    end

    describe '#settings' do

      it 'allows the value to be set only once' do
        NoteRepository.settings(number_of_shards: 3)
        #expect(NoteRepository.settings.to_hash).to eq()
      end

      it 'sets the value at the class level' do
        expect(NoteRepository.settings.to_hash).to eq(number_of_shards: 1, number_of_replicas: 0)
      end

      it 'sets the value as the default at the instance level' do
        expect(NoteRepository.new.settings.to_hash).to eq(number_of_shards: 1, number_of_replicas: 0)
      end

      it 'allows the value to be overwritten with options on the instance' do
        expect(NoteRepository.new(settings: { number_of_shards: 3 }).settings.to_hash).to eq({ number_of_shards: 3 })
      end

      it 'allows the value to be overwritten when #with is called on an instance' do
        expect(NoteRepository.new.with(settings: { number_of_shards: 3 }).settings.to_hash).to eq({ number_of_shards: 3 })
      end
    end
  end
end
