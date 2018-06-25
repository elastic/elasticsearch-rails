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

  desc "Run Elasticsearch (Docker)"
  task :setup_elasticsearch do
    begin
      sh <<-COMMAND.gsub(/^\s*/, '').gsub(/\s{1,}/, ' ')
          docker stop $(docker ps -aq);
          docker rm $(docker ps -aq);
          docker rmi $(docker images -q);
          docker run -d=true \
            --env "discovery.type=single-node" \
            --env "cluster.name=elasticsearch-rails" \
            --env "http.port=9200" \
            --env "cluster.routing.allocation.disk.threshold_enabled=false" \
            --publish 9250:9200 \
            --rm \
            docker.elastic.co/elasticsearch/elasticsearch:6.3.0
      COMMAND
      require 'elasticsearch/extensions/test/cluster'
      Elasticsearch::Extensions::Test::Cluster::Cluster.new(version: '6.3.0',
                                                            number_of_nodes: 1).wait_for_green
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
