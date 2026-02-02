# app/controllers/application_controller.rb
#
# Base controller for the application. Runs in API-only mode (no views, sessions, or CSRF).
# Global SPARQL endpoint configuration is in config/initializers/sparql.rb.
#
require 'open-uri'

class ApplicationController < ActionController::API
  include Pagy::Backend

  before_action do
    create_queries_container
  end

  private

  # Initialises an empty queries array for tracking SPARQL queries
  # executed during the request (included in API responses for debugging)
  #
  def create_queries_container
    @queries = []
  end
end
