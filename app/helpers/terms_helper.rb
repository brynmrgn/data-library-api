module TermsHelper

    def get_term_label ( term_id )
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
        response = Net::HTTP.post( $SPARQL_REQUEST_URI, query, {'Content-Type': 'application/sparql-query', 'Accept': 'application/sparql-results+json'} )
        term = JSON.parse(response.body)
        term_label = term['results']['bindings'][0]['termLabel']['value']
        logger.warn term_label
        term_label
    end
end

