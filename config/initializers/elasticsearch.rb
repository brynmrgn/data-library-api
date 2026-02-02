# config/initializers/elasticsearch.rb
#
# Configures the Elasticsearch client for search functionality.
# Uses BONSAI_URL (set by Heroku Bonsai add-on) or falls back to localhost.
#
require 'elasticsearch'

ELASTICSEARCH_CLIENT = Elasticsearch::Client.new(
  url: ENV.fetch('BONSAI_URL', 'http://localhost:9200'),
  log: Rails.env.development?
)
