module SparqlHttpHelper
  extend ActiveSupport::Concern

  included do
    # Make it available as both instance and class method
    def self.sparql_post(uri, body, headers)
      SparqlHttpHelper.execute_sparql_post(uri, body, headers)
    end
  end

  def sparql_post(uri, body, headers)
    SparqlHttpHelper.execute_sparql_post(uri, body, headers)
  end

  def self.execute_sparql_post(uri, body, headers)
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
    request.body = body
    
    http.request(request)
  end
end