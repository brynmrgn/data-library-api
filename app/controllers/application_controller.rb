require 'open-uri'

class ApplicationController < ActionController::Base
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  $SPARQL_REQUEST_URI = URI( 'https://data-odp.parliament.uk/sparql' )
  $SPARQL_REQUEST_HEADERS = { 'Content-Type': 'application/sparql-query', 'Accept': 'application/ld+json' }
  $SPARQL_COUNT_HEADERS = { 'Content-Type': 'application/sparql-query', 'Accept': 'application/sparql-results+json' }
  $DATE_DISPLAY_FORMAT = '%-d %B %Y'
  $CSV_DATE_DISPLAY_FORMAT = '%-d/%m/%Y'
  $DEFAULT_RESULTS_PER_PAGE = 40
  $MAX_RESULTS_PER_PAGE = 250
  allow_browser versions: :modern

  
  before_action do
    #expires_in 3.minutes, :public => true  
    create_crumb_container
    create_queries_container
  end

  def create_crumb_container
    @crumb = []
  end
  
  def create_queries_container
    @queries = []
  end
end
