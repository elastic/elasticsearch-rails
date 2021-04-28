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

require 'pathname'
require 'elasticsearch'

subprojects = ['elasticsearch-rails', 'elasticsearch-persistence']
subprojects << 'elasticsearch-model' unless defined?(JRUBY_VERSION)

__current__ = Pathname(File.expand_path(__dir__))

def admin_client
  $admin_client ||= begin
    transport_options = {}
    test_suite = ENV['TEST_SUITE'].freeze

    if hosts = ENV['TEST_ES_SERVER'] || ENV['ELASTICSEARCH_HOSTS']
      split_hosts = hosts.split(',').map do |host|
        /(http\:\/\/)?(\S+)/.match(host)[2]
      end

      host, port = split_hosts.first.split(':')
    end

    if test_suite == 'security'
      transport_options.merge!(:ssl => { verify: false,
                                         ca_path: CERT_DIR })

      password = ENV['ELASTIC_PASSWORD']
      user = ENV['ELASTIC_USER'] || 'elastic'
      url = "https://#{user}:#{password}@#{host}:#{port}"
    else
      url = "http://#{host || 'localhost'}:#{port || 9200}"
    end
    Elasticsearch::Client.new(host: url, transport_options: transport_options)
  end
end

task :default do
  system 'rake --tasks'
end

task :subprojects do
  puts '-'*80
  subprojects.each do |project|
    commit  = `git log --pretty=format:'%h %ar: %s' -1 #{project}`
    version =  Gem::Specification::load(__current__.join(project, "#{project}.gemspec").to_s).version.to_s
    puts "[#{version}] \e[1m#{project.ljust(subprojects.map {|s| s.length}.max)}\e[0m | #{commit[ 0..80]}..."
  end
end

desc 'Alias for `bundle:install`'
task bundle: 'bundle:install'

namespace :bundle do
  desc 'Run `bundle install` in all subprojects'
  task :install do
    subprojects.each do |project|
      puts '-'*80
      sh "cd #{__current__.join(project)} && bundle exec rake bundle:install"
      puts
    end
  end

  desc "Remove Gemfile.lock in all subprojects"
  task :clean do
    subprojects.each do |project|
      sh "rm -f #{__current__.join(project)}/Gemfile.lock"
    end
    sh "rm -f #{__current__.join('elasticsearch-model/gemfiles')}/*.lock"
  end
  sh "rm -f Gemfile.lock"
end

namespace :test do
  task :bundle => 'bundle:install'

  desc "Run unit tests in all subprojects"
  task :unit do
    subprojects.each do |project|
      puts '-'*80
      sh "cd #{__current__.join(project)} && unset BUNDLE_GEMFILE && bundle exec rake test:unit"
      puts "\n"
    end
  end

  desc "Setup MongoDB (Docker)"
  task :setup_mongodb_docker do
    begin
      if ENV['MONGODB_VERSION']
        sh <<-COMMAND.gsub(/^\s*/, '').gsub(/\s{1,}/, ' ')
            wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGODB_VERSION}.tgz -O /tmp/mongodb.tgz &&
            tar -xvf /tmp/mongodb.tgz &&
            mkdir /tmp/data &&
            ${PWD}/mongodb-linux-x86_64-${MONGODB_VERSION}/bin/mongod --setParameter enableTestCommands=1 --dbpath /tmp/data --bind_ip 127.0.0.1 --auth &> /dev/null &
        COMMAND
      end
    rescue
    end
  end

  desc "Run integration tests in all subprojects"
  task :integration => :setup_elasticsearch do
    # 1/ elasticsearch-model
    #
    puts '-'*80
    sh "cd #{__current__.join('elasticsearch-model')} && unset BUNDLE_GEMFILE &&" +
       %Q| #{ ENV['TEST_BUNDLE_GEMFILE'] ? "BUNDLE_GEMFILE='#{ENV['TEST_BUNDLE_GEMFILE']}'" : '' }|  +
       " bundle exec rake test:integration"
    puts "\n"

    # 2/ elasticsearch-persistence
    #
    puts '-'*80
    sh "cd #{__current__.join('elasticsearch-persistence')} && unset BUNDLE_GEMFILE &&" +
       " bundle exec rake test:integration"
    puts "\n"

    # 3/ elasticsearch-rails
    #
    puts '-'*80
    sh "cd #{__current__.join('elasticsearch-rails')} && unset BUNDLE_GEMFILE &&" +
       " bundle exec rake test:integration"
    puts "\n"
  end

  desc "Run all tests in all subprojects"
  task :all => :wait_for_green do
    subprojects.each do |project|
      puts '-'*80
      sh "cd #{project} && " +
             "unset BUNDLE_GEMFILE && " +
             "bundle exec rake test:all"
      puts "\n"
    end
  end
end


desc "Wait for elasticsearch cluster to be in green state"
task :wait_for_green do
  require 'elasticsearch'

  ready = nil
  5.times do |i|
    begin
      puts "Attempting to wait for green status: #{i + 1}"
      if admin_client.cluster.health(wait_for_status: 'green', timeout: '50s')
        ready = true
        break
      end
    rescue Elasticsearch::Transport::Transport::Errors::RequestTimeout => ex
      puts "Couldn't confirm green status.\n#{ex.inspect}."
    rescue Faraday::ConnectionFailed => ex
      puts "Couldn't connect to Elasticsearch.\n#{ex.inspect}."
      sleep(30)
    end
  end
  unless ready
    puts "Couldn't connect to Elasticsearch, aborting program."
    exit(1)
  end
end

desc "Generate documentation for all subprojects"
task :doc do
  subprojects.each do |project|
    sh "cd #{__current__.join(project)} && rake doc"
    puts '-'*80
  end
end

desc "Release all subprojects to Rubygems"
task :release do
  subprojects.each do |project|
    sh "cd #{__current__.join(project)} && rake release"
    puts '-'*80
  end
end

desc <<-DESC
  Update Rubygems versions in version.rb and *.gemspec files

  Example:

      $ rake update_version[5.0.0,5.0.1]
DESC
task :update_version, :old, :new do |task, args|
  require 'ansi'

  puts "[!!!] Required argument [old] missing".ansi(:red) unless args[:old]
  puts "[!!!] Required argument [new] missing".ansi(:red) unless args[:new]

  files = Dir['**/**/version.rb','**/**/*.gemspec']

  longest_line = files.map { |f| f.size }.max

  puts "\n", "= FILES ".ansi(:faint) + ('='*92).ansi(:faint), "\n"

  files.each do |file|
    begin
      File.open(file, 'r+') do |f|
        content = f.read
        if content.match Regexp.new(args[:old])
          content.gsub! Regexp.new(args[:old]), args[:new]
          puts "+ [#{file}]".ansi(:green).ljust(longest_line+20) + " [#{args[:old]}] -> [#{args[:new]}]".ansi(:green,:bold)
          f.rewind
          f.write content
        else
          puts "- [#{file}]".ansi(:yellow).ljust(longest_line+20) + " -".ansi(:faint,:strike)
        end
      end
    rescue Exception => e
      puts "[!!!] #{e.class} : #{e.message}".ansi(:red,:bold)
      raise e
    end
  end

  puts "\n\n", "= CHANGELOG ".ansi(:faint) + ('='*88).ansi(:faint), "\n"

  log = `git --no-pager log --reverse --no-color --pretty='* %s' HEAD --not v#{args[:old]} elasticsearch-*`.split("\n")

  puts log.join("\n")

  log_entries = {}
  log_entries[:common] = log.reject { |l| l =~ /^* \[/ }
  log_entries[:model] = log.select { |l| l =~ /^* \[MODEL\]/ }
  log_entries[:store] = log.select { |l| l =~ /^* \[STORE\]/ }
  log_entries[:rails] = log.select { |l| l =~ /^* \[RAILS\]/ }

  changelog = File.read(File.open('CHANGELOG.md', 'r'))

  changelog_update = ''

  changelog_update << "## #{args[:new]}\n\n"

  unless log_entries[:common].empty?
    changelog_update << log_entries[:common]
                          .map { |l| "#{l}" }
                          .join("\n")
    changelog_update << "\n\n"
  end

  unless log_entries[:model].empty?
    changelog_update << "### ActiveModel\n\n"
    changelog_update << log_entries[:model]
                          .map { |l| l.gsub /\[.+\] /, '' }
                          .map { |l| "#{l}" }
                          .join("\n")
    changelog_update << "\n\n"
  end

  unless log_entries[:store].empty?
    changelog_update << "### Persistence\n\n"
    changelog_update << log_entries[:store]
                          .map { |l| l.gsub /\[.+\] /, '' }
                          .map { |l| "#{l}" }
                          .join("\n")
    changelog_update << "\n\n"
  end

  unless log_entries[:rails].empty?
    changelog_update << "### Ruby on Rails\n\n"
    changelog_update << log_entries[:rails]
                          .map { |l| l.gsub /\[.+\] /, '' }
                          .map { |l| "#{l}" }
                          .join("\n")
    changelog_update << "\n\n"
  end

  unless changelog =~ /^## #{args[:new]}/
    File.open('CHANGELOG.md', 'w+') { |f| f.write changelog_update and f.write changelog }
  end

  puts "\n\n", "= DIFF ".ansi(:faint) + ('='*93).ansi(:faint)

  diff = `git --no-pager diff --patch --word-diff=color --minimal elasticsearch-*`.split("\n")

  puts diff
          .reject { |l| l =~ /^\e\[1mdiff \-\-git/ }
          .reject { |l| l =~ /^\e\[1mindex [a-z0-9]{7}/ }
          .reject { |l| l =~ /^\e\[1m\-\-\- i/ }
          .reject { |l| l =~ /^\e\[36m@@/ }
          .map    { |l| l =~ /^\e\[1m\+\+\+ w/ ? "\n#{l}   " + '-'*(104-l.size) : l }
          .join("\n")

  puts "\n\n", "= COMMIT ".ansi(:faint) + ('='*91).ansi(:faint), "\n"

  puts  "git add CHANGELOG.md elasticsearch-*",
        "git commit --verbose --message='Release #{args[:new]}' --edit",
        "rake release"
        "\n"
end
