 # We include code required.
require 'uri'
require 'net/http'
require 'json'
require 'rubygems'
require 'json/ld'

module Sparql::Get::Response
  include SparqlHttpHelper

  
  def get_sparql_response(request_body, frame)
    # We add the SPARQL query request body to the array of queries.
    @queries << request_body
    
    response = sparql_post($SPARQL_REQUEST_URI, request_body, $SPARQL_REQUEST_HEADERS)
    data = JSON.parse(response.body)
    frame = JSON.parse(frame)
    data2 = JSON::LD::API.frame(data, frame)

    data2
  end
end