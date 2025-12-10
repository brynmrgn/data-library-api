# app/helpers/terms_helper.rb
module TermsHelper
  include SparqlHttpHelper
  
  def get_term_label(term_id)
    require 'json'
    query = "
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    
    SELECT ?termLabel ?firstName ?surname
    WHERE {
      VALUES ?item {
        <http://data.parliament.uk/terms/#{term_id}>
      }
      ?item skos:prefLabel ?termLabel .
      OPTIONAL { ?item foaf:firstName ?firstName . }
      OPTIONAL { ?item foaf:surname ?surname . }
    }
    "
    
    response = sparql_post($SPARQL_REQUEST_URI, query, {
      'Content-Type': 'application/sparql-query', 
      'Accept': 'application/sparql-results+json'
    })
    
    term = JSON.parse(response.body)
    binding = term['results']['bindings'][0]
    
    # Try foaf:firstName and foaf:surname first
    if binding['firstName'] && binding['surname']
      first_name = binding['firstName']['value']
      surname = binding['surname']['value']
      term_label = "#{first_name} #{surname}"
    else
      term_label = binding['termLabel']['value']
      
      # If it looks like "Surname, Firstname", reverse it to "Firstname Surname"
      if term_label =~ /^(.+),\s*(.+)$/
        term_label = "#{$2} #{$1}"
      end
    end
    
    term_label
  end
end