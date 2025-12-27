# app/services/sparql_http_helper.rb
#
# HTTP helper for executing SPARQL queries against the Parliament endpoint.
# Handles SSL configuration, JSON-LD framing, and response processing.
#
# Used by:
#   - SparqlGetObject for resource queries (CONSTRUCT + framing)
#   - SparqlItemsCount for count queries (SELECT)
#   - TermsController for term queries (SELECT)
#
require 'uri'
require 'net/http'
require 'json'
require 'json/ld'

module SparqlHttpHelper
  extend ActiveSupport::Concern

  # Instance method that delegates to class method
  def sparql_post(uri, body, headers, model_class = nil)
    SparqlHttpHelper.execute_sparql_post(uri, body, headers, model_class)
  end

  # Executes a SPARQL query via HTTP POST
  #
  # @param uri [String] SPARQL endpoint URL
  # @param query [String] SPARQL query string
  # @param headers [Hash] HTTP headers (Accept determines response format)
  # @param model_class [Class] Optional model class for JSON-LD framing
  # @return [Net::HTTPResponse] HTTP response (body may be framed JSON-LD)
  #
  def self.execute_sparql_post(uri, query, headers, model_class = nil)
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
      apply_json_ld_frame(response, model_class)
    else
      response
    end
  end

  def self.apply_json_ld_frame(response, model_class)
    require 'json/ld'

    response_body_text = response.body
    Rails.logger.debug { "[SPARQL] Response body: #{response_body_text[0..500]}" }

    if response_body_text.include?('Query interrupted')
      raise "SPARQL query timed out or failed: #{response_body_text}"
    end

    response_body = JSON.parse(response_body_text)

    frame = SparqlQueryBuilder.frame(model_class)

    framed_data = JSON::LD::API.frame(response_body, frame)

    response.define_singleton_method(:body) { framed_data.to_json }
    response
  end
end