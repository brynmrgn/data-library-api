# app/services/sparql_http_helper.rb
require 'uri'
require 'net/http'
require 'json'
require 'json/ld'

module SparqlHttpHelper
  extend ActiveSupport::Concern

  # Instance method that delegates to class method
  def sparql_post(uri, body, headers, model_class = nil, attributes = nil)
    SparqlHttpHelper.execute_sparql_post(uri, body, headers, model_class, attributes)
  end

  def self.execute_sparql_post(uri, query, headers, model_class = nil, attributes = nil)
    uri = URI(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    # Only disable SSL verification in development
    if Rails.env.development?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.cert_store = OpenSSL::X509::Store.new
      http.cert_store.set_default_paths
    end
    
    request = Net::HTTP::Post.new(uri.path)
    headers.each { |key, value| request[key.to_s] = value }
    request.body = query
    
    response = http.request(request)
    
    # Check for both symbol and string keys
    accept_header = headers['Accept'] || headers[:Accept]
    if accept_header == 'application/ld+json' && model_class
      apply_json_ld_frame(response, model_class, attributes)
    else
      response
    end
  end

  def self.apply_json_ld_frame(response, model_class, attributes)
    require 'json/ld'
    
    response_body_text = response.body
    puts "Response body: #{response_body_text[0..500]}"  # First 500 chars

    if response_body_text.include?('Query interrupted')
      raise "SPARQL query timed out or failed: #{response_body_text}"
    end

response_body = JSON.parse(response_body_text)
    sparql_type = model_class::SPARQL_TYPE.gsub(/[<>]/, '')
    
    frame = SparqlQueryBuilder.frame(model_class, attributes)
    
    framed_data = JSON::LD::API.frame(response_body, frame)
    
    response.define_singleton_method(:body) { framed_data.to_json }
    response
  end

  def get_sparql_response(request_body, frame)
    # We add the SPARQL query request body to the array of queries.
    @queries ||= []
    @queries << request_body
    
    response = sparql_post($SPARQL_REQUEST_URI, request_body, $SPARQL_REQUEST_HEADERS)
    data = JSON.parse(response.body)
    frame = JSON.parse(frame)
    data2 = JSON::LD::API.frame(data, frame)

    data2
  end
end