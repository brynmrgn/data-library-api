# app/controllers/application_controller.rb
#
# Base controller for the application. Runs in API-only mode (no views, sessions, or CSRF).
# Global SPARQL endpoint configuration is in config/initializers/sparql.rb.
#
require 'open-uri'

class ApplicationController < ActionController::API
  include Pagy::Backend

  before_action :authenticate_api_key
  before_action :create_queries_container

  private

  # Checks for a valid API key in the X-Api-Key header.
  # If API_KEY is not set in the environment, authentication is skipped
  # (allows local development without a key).
  #
  def authenticate_api_key
    expected_key = ENV['API_KEY']
    return if expected_key.blank?

    provided_key = request.headers['X-Api-Key']
    unless ActiveSupport::SecurityUtils.secure_compare(provided_key.to_s, expected_key)
      render json: { error: 'Invalid or missing API key' }, status: :unauthorized
    end
  end

  # Initialises an empty queries array for tracking SPARQL queries
  # executed during the request (included in API responses for debugging)
  #
  def create_queries_container
    @queries = []
  end
end
