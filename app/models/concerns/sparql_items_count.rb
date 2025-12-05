# app/models/concerns/sparql_query_service.rb
module SparqlItemsCount
  include SparqlHttpHelper
  require 'cgi'

  ITEM_TYPES = {
    research_briefing: '<http://data.parliament.uk/schema/parl#ResearchBriefing>',
    deposited_paper: '<http://data.parliament.uk/schema/parl#DepositedPaper>'
  }.freeze

  def self.get_items_count(type_key, filter = "")
    item_type = ITEM_TYPES[type_key.to_sym]
    raise ArgumentError, "Unknown item type: #{type_key}" unless item_type

    query = <<~SPARQL
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX dc-term: <http://purl.org/dc/terms/>
      SELECT (COUNT(DISTINCT ?item) AS ?total)
      WHERE {
        ?item a #{item_type} ;
        dc-term:date ?date .
        #{filter}
      }
    SPARQL
    
    uri = $SPARQL_REQUEST_URI
    body = "query=#{CGI.escape(query)}"
    headers = { 
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Accept' => 'application/sparql-results+json'
    }
    
    response = sparql_post(uri, body, headers)
    data = JSON.parse(response.body)
    data["results"]["bindings"][0]["total"]["value"].to_i
  end
end