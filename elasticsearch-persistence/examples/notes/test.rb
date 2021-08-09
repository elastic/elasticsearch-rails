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

ENV['RACK_ENV'] = 'test'

at_exit { Elasticsearch::Test::IntegrationTestCase.__run_at_exit_hooks } if ENV['SERVER']

require 'test/unit'
require 'shoulda-context'
require 'mocha/setup'
require 'rack/test'
require 'turn'

require 'elasticsearch/extensions/test/cluster'
require 'elasticsearch/extensions/test/startup_shutdown'

require_relative 'application'

NoteRepository.index_name = 'notes_test'

class Elasticsearch::Persistence::ExampleApplicationTest < Test::Unit::TestCase
  include Rack::Test::Methods
  alias :response :last_response

  def app
    Application.new
  end

  context "Note" do
    should "be initialized with a Hash" do
      note = Note.new 'foo' => 'bar'
      assert_equal 'bar', note.attributes['foo']
    end

    should "add created_at when it's not passed" do
      note = Note.new
      assert_not_nil note.created_at
      assert_match   /#{Time.now.year}/, note.created_at
    end

    should "not add created_at when it's passed" do
      note = Note.new 'created_at' => 'FOO'
      assert_equal 'FOO', note.created_at
    end

    should "trim long text" do
      assert_equal 'Hello World', Note.new('text' => 'Hello World').text
      assert_equal 'FOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFOOFO (...)',
                   Note.new('text' => 'FOO'*200).text
    end

    should "delegate methods to attributes" do
      note = Note.new 'foo' => 'bar'
      assert_equal 'bar', note.foo
    end

    should "have tags" do
      assert_not_nil Note.new.tags
    end

    should "provide a `to_hash` method" do
      note = Note.new 'foo' => 'bar'
      assert_instance_of Hash, note.to_hash
      assert_equal ['created_at', 'foo'], note.to_hash.keys.sort
    end

    should "extract tags from the text" do
      note = Note.new 'text' => 'Hello [foo] [bar]'
      assert_equal 'Hello',        note.text
      assert_equal ['foo', 'bar'], note.tags
    end
  end

  context "Application" do
    setup do
      app.settings.repository.client = Elasticsearch::Client.new \
        hosts: [{ host: 'localhost', port: ENV.fetch('TEST_CLUSTER_PORT', 9250)}],
        log: true
      app.settings.repository.client.transport.transport.logger.formatter = proc { |s, d, p, m| "\e[2m#{m}\n\e[0m" }
      app.settings.repository.create_index! force: true
      app.settings.repository.client.cluster.health wait_for_status: 'yellow'
    end

    should "have the correct index name" do
      assert_equal 'notes_test', app.settings.repository.index
    end

    should "display empty page when there are no notes" do
      get '/'
      assert response.ok?,           response.status.to_s
      assert_match /No notes found/, response.body.to_s
    end

    should "display the notes" do
      app.settings.repository.save Note.new('text' => 'Hello')
      app.settings.repository.refresh_index!

      get '/'
      assert response.ok?,        response.status.to_s
      assert_match /<p>\s*Hello/, response.body.to_s
    end

    should "create a note" do
      post '/', { 'text' => 'Hello World' }
      follow_redirect!

      assert response.ok?,        response.status.to_s
      assert_match /Hello World/, response.body.to_s
    end

    should "delete a note" do
      app.settings.repository.save Note.new('id' => 'foobar', 'text' => 'Perish...')
      delete "/foobar"
      follow_redirect!

      assert response.ok?,      response.status.to_s
      assert_no_match /Perish/, response.body.to_s
    end
  end

end
