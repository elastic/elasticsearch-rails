require "rails/generators/elasticsearch_generator"

module Elasticsearch
  module Generators
    class ModelGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)

      desc "Creates an Elasticsearch::Persistence model"
      argument :attributes, type: :array, default: [], banner: "attribute:type attribute:type"

      check_class_collision

      def create_model_file
        @padding = attributes.map { |a| a.name.size }.max
        template "model.rb.tt", File.join("app/models", class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
