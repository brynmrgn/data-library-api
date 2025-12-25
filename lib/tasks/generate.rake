# lib/tasks/generate.rake
namespace :generate do
  desc "Generate models, queries, and frames from config/models.yml"
  task models: :environment do
    require_relative '../generators/model_generator'
    ModelGenerator.generate_all
  end
end
