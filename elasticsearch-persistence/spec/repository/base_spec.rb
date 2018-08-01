require 'spec_helper'

describe Elasticsearch::Persistence::Repository::Base do

  before do
    class MyRepository < Elasticsearch::Persistence::Repository::Base; end
  end

  after do
    begin; Elasticsearch::Persistence::Repository::Base.delete_index!; rescue; end
    Elasticsearch::Persistence::Repository::Base.client = DEFAULT_CLIENT
    begin; MyRepository.delete_index!; rescue; end
    Object.send(:remove_const, MyRepository.name) if defined?(MyRepository)
  end

  shared_examples 'a base repository' do

    describe '#client' do

      context 'when client is not passed as an argument' do

        it 'returns the default client' do
          expect(repository.client).to be_a(Elasticsearch::Transport::Client)
        end

        context 'when the method is called more than once' do

          it 'returns the same client' do
            expect(repository.client).to be(repository.client)
          end
        end
      end

      context 'when a client is passed as an argument' do

        let(:new_client) do
          Elasticsearch::Transport::Client.new
        end

        before do
          repository.client(new_client)
        end

        it 'sets the client' do
          expect(repository.client).to be(new_client)
        end

        context 'when the method is called more than once' do

          it 'returns the same client' do
            repository.client
            expect(repository.client).to be(new_client)
          end
        end

        context 'when the client is nil' do

          before do
            repository.client(nil)
          end

          it 'does not set the client to nil' do
            expect(repository.client).to be_a(Elasticsearch::Transport::Client)
          end
        end
      end
    end

    describe '#client=' do

      let(:new_client) do
        Elasticsearch::Transport::Client.new
      end

      before do
        repository.client = new_client
      end

      it 'sets the new client' do
        expect(repository.client).to be(new_client)
      end

      context 'when the client is set to nil' do

        before do
          repository.client = nil
        end

        it 'falls back to a default client' do
          expect(repository.client).to be_a(Elasticsearch::Transport::Client)
        end
      end
    end

    describe '#index_name' do

      context 'when name is not passed as an argument' do

        it 'returns the default index name' do
          expect(repository.index_name).to eq('repository')
        end

        context 'when the method is called more than once' do

          it 'returns the same index name' do
            expect(repository.index_name).to be(repository.index_name)
          end
        end
      end

      context 'when a name is passed as an argument' do

        let(:new_name) do
          'my_other_repository'
        end

        before do
          repository.index_name(new_name)
        end

        it 'sets the index name' do
          expect(repository.index_name).to eq(new_name)
        end

        context 'when the method is called more than once' do

          it 'returns the same name' do
            repository.index_name
            expect(repository.index_name).to eq(new_name)
          end
        end

        context 'when the name is nil' do

          before do
            repository.index_name(nil)
          end

          it 'does not set the name to nil' do
            expect(repository.index_name).to eq(new_name)
          end
        end
      end
    end

    describe '#index_name=' do

      let(:new_name) do
        'my_other_repository'
      end

      before do
        repository.index_name = new_name
      end

      it 'sets the index name' do
        expect(repository.index_name).to eq(new_name)
      end

      context 'when the name is set to nil' do

        before do
          repository.index_name = nil
        end

        it 'falls back to the default repository name' do
          expect(repository.index_name).to eq('repository')
        end
      end
    end

    describe '#document_type' do

      context 'when type is not passed as an argument' do

        it 'returns the default document type' do
          expect(repository.document_type).to eq('_doc')
        end

        context 'when the method is called more than once' do

          it 'returns the same type' do
            expect(repository.document_type).to be(repository.document_type)
          end
        end
      end

      context 'when a type is passed as an argument' do

        let(:new_type) do
          'other_document_type'
        end

        before do
          repository.document_type(new_type)
        end

        it 'sets the type' do
          expect(repository.document_type).to be(new_type)
        end

        context 'when the method is called more than once' do

          it 'returns the same type' do
            repository.document_type
            expect(repository.document_type).to be(new_type)
          end
        end

        context 'when the type is nil' do

          before do
            repository.document_type(nil)
          end

          it 'does not set the document_type to nil' do
            expect(repository.document_type).to eq(new_type)
          end
        end
      end
    end

    describe '#document_type=' do

      let(:new_type) do
        'other_document_type'
      end

      before do
        repository.document_type = new_type
      end

      it 'sets the new type' do
        expect(repository.document_type).to be(new_type)
      end

      context 'when the document type is set to nil' do

        before do
          repository.document_type = nil
        end

        it 'falls back to a default document type' do
          expect(repository.document_type).to eq('_doc')
        end
      end
    end

    describe '#klass' do

      context 'when class is not passed as an argument' do

        it 'returns nil' do
          expect(repository.klass).to be_nil
        end
      end

      context 'when a class is passed as an argument' do

        let(:new_class) do
          Hash
        end

        before do
          repository.klass(new_class)
        end

        it 'sets the class' do
          expect(repository.klass).to be(new_class)
        end

        context 'when the method is called more than once' do

          it 'returns the same type' do
            repository.klass
            expect(repository.klass).to be(new_class)
          end
        end

        context 'when the class is nil' do

          before do
            repository.klass(nil)
          end

          it 'does not set the class to nil' do
            expect(repository.klass).to eq(new_class)
          end
        end
      end
    end

    describe '#klass=' do

      let(:new_class) do
        Hash
      end

      before do
        repository.klass = new_class
      end

      it 'sets the new class' do
        expect(repository.klass).to be(new_class)
      end

      context 'when the class is set to nil' do

        before do
          repository.klass = nil
        end

        it 'sets the class to nil' do
          expect(repository.klass).to be_nil
        end
      end
    end
  end

  shared_examples 'a singleton' do

    describe '#client' do

      context 'when the client is changed on the class' do

        let(:new_client) do
          Elasticsearch::Transport::Client.new
        end

        before do
          repository.client(new_client)
        end

        it 'applies to the singleton instance as well' do
          expect(repository.instance.client).to be(new_client)
        end
      end
    end

    describe '#index_name' do

      context 'when the index name is changed on the class' do

        let!(:new_name) do
          'my_other_repository'
        end

        before do
          repository.index_name(new_name)
        end

        it 'applies to the singleton instance as well' do
          expect(repository.instance.index_name).to be(new_name)
        end
      end
    end

    describe '#document_type' do

      context 'when the document type is changed on the class' do

        let!(:new_type) do
          'my_other_document_type'
        end

        before do
          repository.document_type(new_type)
        end

        it 'applies to the singleton instance as well' do
          expect(repository.instance.document_type).to be(new_type)
        end
      end
    end

    describe '#klass' do

      context 'when the klass is changed on the class' do

        let(:new_class) do
          Hash
        end

        before do
          repository.klass = new_class
        end

        it 'applies to the singleton instance as well' do
          expect(repository.instance.klass).to be(new_class)
        end
      end
    end
  end

  describe 'inheritance' do

    context 'when the client is changed on the base repository' do

      let(:new_client) do
        Elasticsearch::Transport::Client.new
      end

      before do
        Elasticsearch::Persistence::Repository::Base.client = new_client
      end

      it 'it changes the client on a descendant repository' do
        expect(Elasticsearch::Persistence::Repository::Base.client).to be(new_client)
        expect(MyRepository.client).to be(new_client)
      end
    end

    context 'when the client is changed on a descendant repository' do

      let(:new_client) do
        Elasticsearch::Transport::Client.new
      end

      before do
        MyRepository.client = new_client
      end

      it 'it does not change the client on the base repository' do
        expect(MyRepository.client).to be(new_client)
        expect(Elasticsearch::Persistence::Repository::Base.client).not_to be(new_client)
      end
    end

    context 'when the base repository has a custom index name' do

      before do
        Elasticsearch::Persistence::Repository::Base.index_name = 'other_index'
      end

      after do
        Elasticsearch::Persistence::Repository::Base.index_name = nil
      end

      it 'it changes the index name on a descendant repository' do
        expect(Elasticsearch::Persistence::Repository::Base.index_name).to eq('other_index')
        expect(MyRepository.index_name).to eq('other_index')
      end

      context 'when the descendant has a custom index name' do

        before do
          MyRepository.index_name = 'my_other_index'
        end

        it 'it applies the custom index name only on a descendant repository' do
          expect(Elasticsearch::Persistence::Repository::Base.index_name).to eq('other_index')
          expect(MyRepository.index_name).to eq('my_other_index')
        end

        context 'when the index_name is reset' do

          before do
            MyRepository.index_name = nil
          end

          it 'falls back to the default index name' do
            expect(MyRepository.index_name).to eq('other_index')
          end
        end
      end
    end

    context 'when there are multiple levels of inheritance' do

      context 'when the descendant does not have custom settings' do

        before do
          MyRepository.index_name = 'my_repository'
          class MyDescendantRepository < MyRepository; end
        end

        after do
          Object.send(:remove_const, MyDescendantRepository.name) if defined?(MyDescendantRepository)
        end

        describe '#index_name' do

          it 'uses the index name of its immediate parent' do
            expect(MyDescendantRepository.index_name).to eq('my_repository')
          end
        end

        describe '#client' do

          it 'uses the client of its immediate parent' do
            expect(MyDescendantRepository.client).to be(MyRepository.client)
          end
        end
      end

      context 'when the descendant has custom settings' do

        before do
          MyRepository.index_name = 'my_repository'
          class MyDescendantRepository < MyRepository
            client Elasticsearch::Transport::Client.new
            index_name 'my_descendant_repository'
          end
        end

        after do
          Object.send(:remove_const, MyDescendantRepository.name) if defined?(MyDescendantRepository)
        end

        describe '#index_name' do

          it 'uses its custom index_name' do
            expect(MyDescendantRepository.index_name).to eq('my_descendant_repository')
          end
        end

        describe '#client' do

          it 'uses its custom client' do
            expect(MyDescendantRepository.client).not_to be(MyRepository.client)
          end
        end
      end
    end

    context 'when the descendant defines its own methods' do

      context 'when the method is an instance method' do

        before do
          class MyDescendantRepository < MyRepository
            client Elasticsearch::Transport::Client.new
            index_name 'my_descendant_repository'

            def custom_method
              'custom_value'
            end
          end
        end

        after do
          Object.send(:remove_const, MyDescendantRepository.name) if defined?(MyDescendantRepository)
        end

        it 'allows the methods to be called on the class' do
          expect(MyDescendantRepository.custom_method).to eq('custom_value')
        end

        it 'allows the methods to be called on the singleton instance' do
          expect(MyDescendantRepository.instance.custom_method).to eq('custom_value')
        end
      end

      context 'when the method is a class method' do

        before do
          class MyDescendantRepository < MyRepository
            client Elasticsearch::Transport::Client.new
            index_name 'my_descendant_repository'

            def self.custom_method
              'custom_value'
            end
          end
        end

        after do
          Object.send(:remove_const, MyDescendantRepository.name) if defined?(MyDescendantRepository)
        end

        it 'allows the methods to be called on the class' do
          expect(MyDescendantRepository.custom_method).to eq('custom_value')
        end

        it 'allows the methods to be called on the singleton instance' do
          expect(MyDescendantRepository.instance.custom_method).to eq('custom_value')
        end
      end
    end
  end

  context 'when methods are called on the class' do

    let(:repository) do
      MyRepository
    end

    it_behaves_like 'a base repository'
    it_behaves_like 'a singleton'
  end

  context 'when methods are called on the class instance' do

    let(:repository) do
      MyRepository.instance
    end

    it_behaves_like 'a base repository'
  end
end
