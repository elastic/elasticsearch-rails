require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  setup do
    Time.stubs(:now).returns(Time.parse('2015-03-16 10:00:00 UTC'))

    Article.delete_all

    articles = [
      { title: 'Article One', abstract: 'One', content: 'One', published_on: 1.day.ago, category_title: 'One', author_first_name: 'John', author_last_name: 'Smith' },
      { title: 'Article One Another', abstract: '', content: '', published_on: 2.days.ago, category_title: 'One', author_first_name: 'John', author_last_name: 'Smith' },
      { title: 'Article One Two', abstract: '', content: '', published_on: 10.days.ago, category_title: 'Two', author_first_name: 'Mary', author_last_name: 'Smith' },
      { title: 'Article Two', abstract: '', content: '', published_on: 12.days.ago, category_title: 'Two', author_first_name: 'Mary', author_last_name: 'Smith' },
      { title: 'Article Three', abstract: '', content: '', published_on: 12.days.ago, category_title: 'Three', author_first_name: 'Alice', author_last_name: 'Smith' }
    ]

    articles.each do |a|
      article = Article.create! \
        title:    a[:title],
        abstract: a[:abstract],
        content:  a[:content],
        published_on: a[:published_on]

      article.categories << Category.find_or_create_by!(title: a[:category_title])

      article.authors << Author.find_or_create_by!(first_name: a[:author_first_name], last_name: a[:author_last_name])

      article.save!
    end

    Article.find_by_title('Article Three').comments.create body: 'One'

    Sidekiq::Worker.clear_all

    Article.__elasticsearch__.import force: true
    Article.__elasticsearch__.refresh_index!
  end

  test "should return search results" do
    get :index, q: 'one'
    assert_response :success
    assert_equal 3, assigns(:articles).size
  end

  test "should return search results in comments" do
    get :index, q: 'one', comments: 'y'
    assert_response :success

    assert_equal 4, assigns(:articles).size
  end

  test "should return highlighted snippets" do
    get :index, q: 'one'
    assert_response :success
    assert_match %r{<em class="label label-highlight">One</em>}, assigns(:articles).first.highlight.title.first
  end

  test "should return suggestions" do
    get :index, q: 'one'
    assert_response :success

    suggestions = assigns(:articles).response.response['suggest']

    assert_equal 'one', suggestions['suggest_title'][0]['text']
  end

  test "should return facets" do
    get :index, q: 'one'
    assert_response :success

    aggregations = assigns(:articles).response.response['aggregations']

    assert_equal 2, aggregations['categories']['categories']['buckets'].size
    assert_equal 2, aggregations['authors']['authors']['buckets'].size
    assert_equal 2, aggregations['published']['published']['buckets'].size

    assert_equal 'One', aggregations['categories']['categories']['buckets'][0]['key']
    assert_equal 'John Smith', aggregations['authors']['authors']['buckets'][0]['key']
    assert_equal 1425254400000, aggregations['published']['published']['buckets'][0]['key']
  end

  test "should sort on the published date" do
    get :index, q: 'one', s: 'published_on'
    assert_response :success

    assert_equal 3, assigns(:articles).size
    assert_equal '2015-03-15', assigns(:articles)[0].published_on
    assert_equal '2015-03-14', assigns(:articles)[1].published_on
    assert_equal '2015-03-06', assigns(:articles)[2].published_on
  end

  test "should sort on the published date when no query is provided" do
    get :index, q: ''
    assert_response :success

    assert_equal 5, assigns(:articles).size
    assert_equal '2015-03-15', assigns(:articles)[0].published_on
    assert_equal '2015-03-14', assigns(:articles)[1].published_on
    assert_equal '2015-03-06', assigns(:articles)[2].published_on
  end

  test "should filter search results and the author and published date facets when user selects a category" do
    get :index, q: 'one', c: 'One'
    assert_response :success

    assert_equal 2, assigns(:articles).size

    aggregations = assigns(:articles).response.response['aggregations']

    assert_equal 1, aggregations['authors']['authors']['buckets'].size
    assert_equal 1, aggregations['published']['published']['buckets'].size

    # Do NOT filter the category facet
    assert_equal 2, aggregations['categories']['categories']['buckets'].size
  end

  test "should filter search results and the category and published date facets when user selects a category" do
    get :index, q: 'one', a: 'Mary Smith'
    assert_response :success

    assert_equal 1, assigns(:articles).size

    aggregations = assigns(:articles).response.response['aggregations']

    assert_equal 1, aggregations['categories']['categories']['buckets'].size
    assert_equal 1, aggregations['published']['published']['buckets'].size

    # Do NOT filter the authors facet
    assert_equal 2, aggregations['authors']['authors']['buckets'].size
  end
end
