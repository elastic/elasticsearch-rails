require 'spec_helper'

describe Elasticsearch::Persistence::Repository::Search do

  after do
    begin; repository.delete_index!; rescue; end
  end

  describe '#search' do

    let(:repository) do
      DEFAULT_REPOSITORY
    end

    context 'when the repository does not have a type set' do

      before do
        repository.save({ name: 'user' }, refresh: true)
      end

      context 'when a query definition is provided as a hash' do

        it 'uses the default document type' do
          expect(repository.search({ query: { match: { name: 'user' } } }).first).to eq('name' => 'user')
        end
      end

      context 'when a query definition is provided as a string' do

        it 'uses the default document type' do
          expect(repository.search('user').first).to eq('name' => 'user')
        end
      end

      context 'when the query definition is neither a String nor a Hash' do

        it 'raises an ArgumentError' do
          expect {
            repository.search(1)
          }.to raise_exception(ArgumentError)
        end
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the default document type' do
            expect(repository.search({ query: { match: { name: 'user' } } }, type: 'other').first).to be_nil
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the default document type' do
            expect(repository.search('user', type: 'other').first).to be_nil
          end
        end

        context 'when the query definition is neither a String nor a Hash' do

          it 'raises an ArgumentError' do
            expect {
              repository.search(1)
            }.to raise_exception(ArgumentError)
          end
        end
      end
    end

    context 'when the repository does have a type set' do

      let(:repository) do
        MyTestRepository.new(document_type: 'other_note')
      end

      before do
        repository.save({ name: 'user' }, refresh: true)
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the options' do
            expect(repository.search({ query: { match: { name: 'user' } } }, type: 'other').first).to be_nil
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the options' do
            expect(repository.search('user', type: 'other').first).to be_nil
          end
        end

        context 'when the query definition is neither a String nor a Hash' do

          it 'raises an ArgumentError' do
            expect {
              repository.search(1)
            }.to raise_exception(ArgumentError)
          end
        end
      end
    end
  end

  describe '#count' do

    context 'when the repository does not have a type set' do

      let(:repository) do
        DEFAULT_REPOSITORY
      end

      before do
        repository.save({ name: 'user' }, refresh: true)
      end

      context 'when a query definition is provided as a hash' do

        it 'uses the default document type' do
          expect(repository.count({ query: { match: { name: 'user' } } })).to eq(1)
        end
      end

      context 'when a query definition is provided as a string' do

        it 'uses the default document type' do
          expect(repository.count('user')).to eq(1)
        end
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the options' do
            expect(repository.count({ query: { match: { name: 'user' } } }, type: 'other')).to eq(0)
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the options' do
            expect(repository.count('user', type: 'other')).to eq(0)
          end
        end
      end
    end

    context 'when the repository does have a type set' do

      let(:repository) do
        MyTestRepository.new(document_type: 'other_note')
      end

      before do
        repository.save({ name: 'user' }, refresh: true)
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the options' do
            expect(repository.count({ query: { match: { name: 'user' } } }, type: 'other')).to eq(0)
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the options' do
            expect(repository.count('user', type: 'other')).to eq(0)
          end
        end
      end
    end
  end
end
