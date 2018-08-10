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

      context 'when a single id is passed' do

        let!(:id) do
          repository.save(a: 1)['_id']
        end

        it 'retrieves the document' do
          expect(repository.find(id)).to eq('a' => 1)
        end
      end

      context 'when an array of ids is passed' do

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

          it 'nil is returned in the result list for the documents not found' do
            expect(repository.find(ids)).to eq([{ 'a' =>0 },
                                                 nil,
                                                 { 'a' => 2 }])
          end
        end
      end

      context 'when multiple ids is passed' do

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