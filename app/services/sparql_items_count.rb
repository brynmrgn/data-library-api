# app/models/concerns/sparql_items_count.rb
module SparqlItemsCount
  include SparqlHttpHelper
  require 'cgi'

  def self.get_items_count(type_key, filter = "")
  model_class = get_model_class(type_key)
  item_type = model_class::SPARQL_TYPE

  query = <<~SPARQL
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX dc-term: <http://purl.org/dc/terms/>
    PREFIX parl: <http://data.parliament.uk/schema/parl#>
    SELECT (COUNT(DISTINCT ?item) AS ?total)
    WHERE {
      ?item a #{item_type} .
      #{filter}
    }
  SPARQL
  
  # Pass the raw query, not URL-encoded body
  response = SparqlHttpHelper.execute_sparql_post(
    $SPARQL_REQUEST_URI,
    query,
    $SPARQL_COUNT_HEADERS,
    model_class
  )
  
  unless response.is_a?(Net::HTTPSuccess)
    Rails.logger.error("SPARQL count request failed: #{response.code} #{response.body}")
    return 0
  end
  
  data = JSON.parse(response.body)
  data["results"]["bindings"][0]["total"]["value"].to_i
end

  private

  def self.get_model_class(type_key)
    model_class = type_key.to_s.classify.constantize
    raise ArgumentError, "Unknown type: #{type_key}" unless model_class < LinkedDataResource
    model_class
  end
end