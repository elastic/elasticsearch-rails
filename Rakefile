require 'pathname'

subprojects = %w| elasticsearch-rails elasticsearch-persistence elasticsearch-model |

__current__ = Pathname( File.expand_path('..', __FILE__) )

task :default do
  system "rake --tasks"
end

task :subprojects do
  puts '-'*80
  subprojects.each do |project|
    commit  = `git log --pretty=format:'%h %ar: %s' -1 #{project}`
    version =  Gem::Specification::load(__current__.join(project, "#{project}.gemspec").to_s).version.to_s
    puts "[#{version}] \e[1m#{project.ljust(subprojects.map {|s| s.length}.max)}\e[0m | #{commit[ 0..80]}..."
  end
end

desc "Alias for `bundle:install`"
task :bundle => 'bundle:install'

namespace :bundle do
  desc "Run `bundle install` in all subprojects"
  task :install do
    subprojects.each do |project|
      puts '-'*80
      sh "bundle install --gemfile #{__current__.join(project)}/Gemfile"
      puts
    end
    puts '-'*80
    sh "bundle install --gemfile #{__current__.join('elasticsearch-model/gemfiles')}/3.0.gemfile"
    puts '-'*80
    sh "bundle install --gemfile #{__current__.join('elasticsearch-model/gemfiles')}/4.0.gemfile"
    puts '-'*80
    sh "bundle install --gemfile #{__current__.join('elasticsearch-model/gemfiles')}/5.0.gemfile"
  end

  desc "Remove Gemfile.lock in all subprojects"
  task :clean do
    subprojects.each do |project|
      sh "rm -f #{__current__.join(project)}/Gemfile.lock"
    end
    sh "rm -f #{__current__.join('elasticsearch-model/gemfiles')}/3.0.gemfile.lock"
    sh "rm -f #{__current__.join('elasticsearch-model/gemfiles')}/4.0.gemfile.lock"
    sh "rm -f #{__current__.join('elasticsearch-model/gemfiles')}/5.0.gemfile.lock"
  end
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

  desc "Run integration tests in all subprojects"
  task :integration do
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
  task :all do
    Rake::Task['test:unit'].invoke
    Rake::Task['test:integration'].invoke
  end

  namespace :cluster do
    desc "Start Elasticsearch nodes for tests"
    task :start do
      require 'elasticsearch/extensions/test/cluster'
      Elasticsearch::Extensions::Test::Cluster.start
    end

    desc "Stop Elasticsearch nodes for tests"
    task :stop do
      require 'elasticsearch/extensions/test/cluster'
      Elasticsearch::Extensions::Test::Cluster.stop
    end

    task :status do
      require 'elasticsearch/extensions/test/cluster'
      (puts "\e[31m[!] Test cluster not running\e[0m"; exit(1)) unless Elasticsearch::Extensions::Test::Cluster.running?
      Elasticsearch::Extensions::Test::Cluster.__print_cluster_info(ENV['TEST_CLUSTER_PORT'] || 9250)
    end
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
