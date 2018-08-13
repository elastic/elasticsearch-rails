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
