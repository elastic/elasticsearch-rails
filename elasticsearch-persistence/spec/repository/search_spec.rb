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
        repository.save({ name: 'emily' }, refresh: true)
      end

      context 'when a query definition is provided as a hash' do

        it 'uses the default document type' do
          expect(repository.search({ query: { match: { name: 'emily' } } }).first).to eq('name' => 'emily')
        end
      end

      context 'when a query definition is provided as a string' do

        it 'uses the default document type' do
          expect(repository.search('emily').first).to eq('name' => 'emily')
        end
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the default document type' do
            expect(repository.search({ query: { match: { name: 'emily' } } }, type: 'other').first).to be_nil
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the default document type' do
            expect(repository.search('emily', type: 'other').first).to be_nil
          end
        end
      end
    end

    context 'when the repository does have a type set' do

      let(:repository) do
        MyTestRepository.new(document_type: 'other_note')
      end

      before do
        repository.save({ name: 'emily' }, refresh: true)
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the options' do
            expect(repository.search({ query: { match: { name: 'emily' } } }, type: 'other').first).to be_nil
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the options' do
            expect(repository.search('emily', type: 'other').first).to be_nil
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
        repository.save({ name: 'emily' }, refresh: true)
      end

      context 'when a query definition is provided as a hash' do

        it 'uses the default document type' do
          expect(repository.count({ query: { match: { name: 'emily' } } })).to eq(1)
        end
      end

      context 'when a query definition is provided as a string' do

        it 'uses the default document type' do
          expect(repository.count('emily')).to eq(1)
        end
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the options' do
            expect(repository.count({ query: { match: { name: 'emily' } } }, type: 'other')).to eq(0)
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the options' do
            expect(repository.count('emily', type: 'other')).to eq(0)
          end
        end
      end
    end

    context 'when the repository does have a type set' do

      let(:repository) do
        MyTestRepository.new(document_type: 'other_note')
      end

      before do
        repository.save({ name: 'emily' }, refresh: true)
      end

      context 'when options are provided' do

        context 'when a query definition is provided as a hash' do

          it 'uses the options' do
            expect(repository.count({ query: { match: { name: 'emily' } } }, type: 'other')).to eq(0)
          end
        end

        context 'when a query definition is provided as a string' do

          it 'uses the options' do
            expect(repository.count('emily', type: 'other')).to eq(0)
          end
        end
      end
    end
  end
end
