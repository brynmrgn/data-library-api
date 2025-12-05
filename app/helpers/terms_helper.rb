# app/helpers/terms_helper.rb
module TermsHelper
  include SparqlHttpHelper
  
  # not sure why I need this if I'm getting IDs and labels from my SPARQL queries already.

  def get_term_label(term_id)
    require 'json'
    query = "
    PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
    select ?termLabel
    where {
      VALUES ?item {
        <http://data.parliament.uk/terms/#{term_id}>
      }
      ?item skos:prefLabel ?termLabel .
      ?item skos:prefLabel ?broader .
    }
    "
    response = sparql_post($SPARQL_REQUEST_URI, query, {
      'Content-Type': 'application/sparql-query', 
      'Accept': 'application/sparql-results+json'
    })
    term = JSON.parse(response.body)
    term_label = term['results']['bindings'][0]['termLabel']['value']
    logger.warn term_label
    
    term_label  # ADD THIS LINE - return the value!
  end
end