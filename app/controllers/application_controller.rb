require 'open-uri'

class ApplicationController < ActionController::API
  include Pagy::Backend

  # Global SPARQL config is in config/initializers/sparql.rb

  before_action do
    #expires_in 3.minutes, :public => true
    create_queries_container
  end

  def create_queries_container
    @queries = []
  end
end
