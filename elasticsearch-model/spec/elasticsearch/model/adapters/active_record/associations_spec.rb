require 'spec_helper'

describe 'Elasticsearch::Model::Adapter::ActiveRecord Associations' do

  before(:all) do
    ActiveRecord::Schema.define(version: 1) do
      create_table :categories do |t|
        t.string     :title
        t.timestamps null: false
      end

      create_table :categories_posts do |t|
        t.references :post, :category
      end

      create_table :authors do |t|
        t.string     :first_name, :last_name
        t.timestamps null: false
      end

      create_table :authorships do |t|
        t.string     :first_name, :last_name
        t.references :post
        t.references :author
        t.timestamps null: false
      end

      create_table :comments do |t|
        t.string     :text
        t.string     :author
        t.references :post
        t.timestamps null: false
      end

      add_index(:comments, :post_id) unless index_exists?(:comments, :post_id)

      create_table :posts do |t|
        t.string     :title
        t.text       :text
        t.boolean    :published
        t.timestamps null: false
      end
    end

    Comment.__send__ :include, Elasticsearch::Model
    Comment.__send__ :include, Elasticsearch::Model::Callbacks
  end

  before do
    clear_tables(:categories, :categories_posts, :authors, :authorships, :comments, :posts)
    clear_indices(Post)
    Post.__elasticsearch__.create_index!(force: true)
    Comment.__elasticsearch__.create_index!(force: true)
  end

  after do
    clear_tables(Post, Category)
    clear_indices(Post)
  end

  context 'when a document is created' do

    before do
      Post.create!(title: 'Test')
      Post.create!(title: 'Testing Coding')
      Post.create!(title: 'Coding')
      Post.__elasticsearch__.refresh_index!
    end

    let(:search_result) do
      Post.search('title:test')
    end

    it 'indexes the document' do
      expect(search_result.results.size).to eq(2)
      expect(search_result.results.first.title).to eq('Test')
      expect(search_result.records.size).to eq(2)
      expect(search_result.records.first.title).to eq('Test')
    end
  end

  describe 'has_many_and_belongs_to association' do

      context 'when an association is updated' do

      before do
        post.categories = [category_a,  category_b]
        Post.__elasticsearch__.refresh_index!
      end

      let(:category_a) do
        Category.where(title: "One").first_or_create!
      end

      let(:category_b) do
        Category.where(title: "Two").first_or_create!
      end

      let(:post) do
        Post.create! title: "First Post", text: "This is the first post..."
      end

      let(:search_result) do
        Post.search(query: {
            bool: {
                must: {
                    multi_match: {
                        fields: ['title'],
                        query: 'first'
                    }
                },
                filter: {
                    terms: {
                        categories: ['One']
                    }
                }
            }
        } )
      end

      it 'applies the update with' do
        expect(search_result.results.size).to eq(1)
        expect(search_result.results.first.title).to eq('First Post')
        expect(search_result.records.size).to eq(1)
        expect(search_result.records.first.title).to eq('First Post')
      end
    end

    context 'when an association is deleted' do

      before do
        post.categories = [category_a,  category_b]
        post.categories = [category_b]
        Post.__elasticsearch__.refresh_index!
      end

      let(:category_a) do
        Category.where(title: "One").first_or_create!
      end

      let(:category_b) do
        Category.where(title: "Two").first_or_create!
      end

      let(:post) do
        Post.create! title: "First Post", text: "This is the first post..."
      end

      let(:search_result) do
        Post.search(query: {
            bool: {
                must: {
                    multi_match: {
                        fields: ['title'],
                        query: 'first'
                    }
                },
                filter: {
                    terms: {
                        categories: ['One']
                    }
                }
            }
        } )
      end

      it 'applies the update with a reindex' do
        expect(search_result.results.size).to eq(0)
        expect(search_result.records.size).to eq(0)
      end
    end
  end

  describe 'has_many through association' do

    context 'when the association is updated' do

      before do
        author_a = Author.where(first_name: "John", last_name: "Smith").first_or_create!
        author_b = Author.where(first_name: "Mary", last_name: "Smith").first_or_create!
        author_c = Author.where(first_name: "Kobe", last_name: "Griss").first_or_create!

        # Create posts
        post_1 = Post.create!(title: "First Post", text: "This is the first post...")
        post_2 = Post.create!(title: "Second Post", text: "This is the second post...")
        post_3 = Post.create!(title: "Third Post", text: "This is the third post...")

        # Assign authors
        post_1.authors = [author_a,  author_b]
        post_2.authors = [author_a]
        post_3.authors = [author_c]

        Post.__elasticsearch__.refresh_index!
      end

      context 'if active record is at least 4' do

        let(:search_result) do
          Post.search('authors.full_name:john')
        end

        it 'applies the update', if: active_record_at_least_4? do
          expect(search_result.results.size).to eq(2)
          expect(search_result.records.size).to eq(2)
        end
      end

      context 'if active record is less than 4' do

        let(:search_result) do
          Post.search('authors.author.full_name:john')
        end

        it 'applies the update', if: !active_record_at_least_4? do
          expect(search_result.results.size).to eq(2)
          expect(search_result.records.size).to eq(2)
        end
      end
    end

    context 'when an association is added', if: active_record_at_least_4? do

      before do
        author_a = Author.where(first_name: "John", last_name: "Smith").first_or_create!
        author_b = Author.where(first_name: "Mary", last_name: "Smith").first_or_create!

        # Create posts
        post_1 = Post.create!(title: "First Post", text: "This is the first post...")

        # Assign authors
        post_1.authors = [author_a]
        post_1.authors << author_b
        Post.__elasticsearch__.refresh_index!
      end

      let(:search_result) do
        Post.search('authors.full_name:john')
      end

      it 'adds the association' do
        expect(search_result.results.size).to eq(1)
        expect(search_result.records.size).to eq(1)
      end
    end
  end

  describe 'has_many association' do

    context 'when an association is added', if: active_record_at_least_4? do

      before do
        # Create posts
        post_1 = Post.create!(title: "First Post", text: "This is the first post...")
        post_2 = Post.create!(title: "Second Post", text: "This is the second post...")

        # Add comments
        post_1.comments.create!(author: 'John', text: 'Excellent')
        post_1.comments.create!(author: 'Abby', text: 'Good')

        post_2.comments.create!(author: 'John', text: 'Terrible')

        post_1.comments.create!(author: 'John', text: 'Or rather just good...')
        Post.__elasticsearch__.refresh_index!
      end

      let(:search_result) do
        Post.search(query: {
            nested: {
                path: 'comments',
                query: {
                    bool: {
                        must: [
                            { match: { 'comments.author' => 'john' } },
                            { match: { 'comments.text'   => 'good' } }
                        ]
                    }
                }
            }
        })
      end

      it 'adds the association' do
        expect(search_result.results.size).to eq(1)
      end
    end
  end

  describe '#touch' do

    context 'when a touch callback is defined on the model' do

      before do
        # Create categories
        category_a = Category.where(title: "One").first_or_create!

        # Create post
        post = Post.create!(title: "First Post", text: "This is the first post...")

        # Assign category
        post.categories << category_a
        category_a.update_attribute(:title, "Updated")
        category_a.posts.each { |p| p.touch }

        Post.__elasticsearch__.refresh_index!
      end

      it 'executes the callback after #touch' do
        expect(Post.search('categories:One').size).to eq(0)
        expect(Post.search('categories:Updated').size).to eq(1)
      end
    end
  end

  describe '#includes' do

    before do
      post_1 = Post.create(title: 'One')
      post_2 = Post.create(title: 'Two')
      post_1.comments.create(text: 'First comment')
      post_2.comments.create(text: 'Second comment')

      Comment.__elasticsearch__.refresh_index!
    end

    let(:search_result) do
      Comment.search('first').records(includes: :post)
    end

    it 'eager loads associations' do
      expect(search_result.first.association(:post)).to be_loaded
      expect(search_result.first.post.title).to eq('One')
    end
  end
end
