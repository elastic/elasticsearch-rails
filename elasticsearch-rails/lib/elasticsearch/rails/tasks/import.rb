# A collection of Rake tasks to facilitate importing data from your models into Elasticsearch.
#
# Add this e.g. into the `lib/tasks/elasticsearch.rake` file in your Rails application:
#
#     require 'elasticsearch/rails/tasks/import'
#
# To import the records from your `Article` model, run:
#
#     $ bundle exec rake environment elasticsearch:import:model CLASS='MyModel'
#
# Run this command to display usage instructions:
#
#     $ bundle exec rake -D elasticsearch
#
STDOUT.sync = true
STDERR.sync = true

begin; require 'ansi/progressbar'; rescue LoadError; end

namespace :elasticsearch do

  task :import => 'import:model'

  namespace :import do
    import_model_desc = <<-DESC.gsub(/    /, '')
      Import data from your model (pass name as CLASS environment variable).

        $ rake environment elasticsearch:import:model CLASS='MyModel'

      Force rebuilding the index (delete and create):
        $ rake environment elasticsearch:import:model CLASS='Article' FORCE=y

      Customize the batch size:
        $ rake environment elasticsearch:import:model CLASS='Article' BATCH=100

      Set target index name:
        $ rake environment elasticsearch:import:model CLASS='Article' INDEX='articles-new'

      Pass an ActiveRecord scope to limit the imported records:
        $ rake environment elasticsearch:import:model CLASS='Article' SCOPE='published'

      Import data from your model concurrently:
        $ rake environment elasticsearch:import:model CLASS='Article' PARTITION=2 BY=id

    DESC
    desc import_model_desc
    task :model do
      if ENV['CLASS'].to_s == ''
        puts '='*90, 'USAGE', '='*90, import_model_desc, ""
        exit(1)
      end

      klass  = eval(ENV['CLASS'].to_s)
      total  = klass.count rescue nil
      partition = ENV['PARTITION'].to_i

      unless ENV['DEBUG']
        begin
          klass.__elasticsearch__.client.transport.logger.level = Logger::WARN
        rescue NoMethodError; end
        begin
          klass.__elasticsearch__.client.transport.tracer.level = Logger::WARN
        rescue NoMethodError; end
      end

      options = {
        batch_size: ENV.fetch('BATCH', 1000).to_i,
        index:      ENV.fetch('INDEX', nil),
        type:       ENV.fetch('TYPE',  nil),
        scope:      ENV.fetch('SCOPE', nil)
      }

      if partition > 1
        by = ENV.fetch('BY', klass.primary_key)
        scope = ENV.fetch('SCOPE', nil)
        Rails.application.eager_load!

        query = scope ? klass.send(scope) : klass
        per_partition = (query.count.to_f / partition.to_f).ceil

        # recreate index if forced
        klass.__elasticsearch__.create_index!(force: true, index: klass.index_name) if ENV.fetch('FORCE', false)

        partition.times do |index|
          from_range = index == 0 ? 1 : query.offset(index * (per_partition)).first.try(by.to_sym) + 1
          to_range = index == partition - 1 ? query.last.send(by) : query.offset((index + 1) * per_partition).first.try(by.to_sym)
          eval(%Q{
            pid = fork do
              klass.__elasticsearch__.import options.merge(force: false, query: Proc.new { where(by => #{from_range}..#{to_range}) })
            end
            puts "[IMPORT] PID \#{pid} processing:  #{from_range}..#{to_range}"
          })
        end

      else
        pbar   = ANSI::Progressbar.new(klass.to_s, total) rescue nil
        pbar.__send__ :show if pbar
        total_errors = klass.__elasticsearch__.import(options.merge(force: ENV.fetch('FORCE', false))) do |response|
          pbar.inc response['items'].size if pbar
          STDERR.flush
          STDOUT.flush
        end
        pbar.finish if pbar

        puts "[IMPORT] #{total_errors} errors occurred" unless total_errors.zero?
        puts '[IMPORT] Done'
      end
    end

    desc <<-DESC.gsub(/    /, '')
      Import all indices from `app/models` (or use DIR environment variable).

        $ rake environment elasticsearch:import:all DIR=app/models
    DESC
    task :all do
      dir    = ENV['DIR'].to_s != '' ? ENV['DIR'] : Rails.root.join("app/models")

      puts "[IMPORT] Loading models from: #{dir}"
      Dir.glob(File.join("#{dir}/**/*.rb")).each do |path|
        model_filename = path[/#{Regexp.escape(dir.to_s)}\/([^\.]+).rb/, 1]

        next if model_filename.match(/^concerns\//i) # Skip concerns/ folder

        begin
          klass = model_filename.camelize.constantize
        rescue NameError
          require(path) ? retry : raise(RuntimeError, "Cannot load class '#{klass}'")
        end

        # Skip if the class doesn't have Elasticsearch integration
        next unless klass.respond_to?(:__elasticsearch__)

        puts "[IMPORT] Processing model: #{klass}..."

        ENV['CLASS'] = klass.to_s
        Rake::Task["elasticsearch:import:model"].invoke
        Rake::Task["elasticsearch:import:model"].reenable
        puts
      end
    end

  end

end
