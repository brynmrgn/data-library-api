namespace :search do
  desc "Create Elasticsearch index with mappings"
  task setup: :environment do
    SearchIndexService.create_index
    puts "Index created."
  end

  desc "Reindex all resources from SPARQL into Elasticsearch"
  task reindex: :environment do
    SearchIndexService.reindex_all
    puts "Reindex complete."
  end

  desc "Drop and recreate the index, then reindex all resources"
  task reset: :environment do
    SearchIndexService.delete_index
    SearchIndexService.create_index
    SearchIndexService.reindex_all
    puts "Index reset and reindexed."
  end
end
