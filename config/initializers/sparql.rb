# config/initializers/sparql.rb
#
# SPARQL endpoint configuration.
# Previously set in ApplicationController, moved here so globals are
# available to rake tasks and other non-request contexts.
#
require 'uri'

$SPARQL_REQUEST_URI = URI(
  ENV.fetch('SPARQL_ENDPOINT', 'https://data-services.parliament.uk/sparql')
)

$SPARQL_SUBSCRIPTION_KEY = ENV.fetch('SPARQL_SUBSCRIPTION_KEY', '')

$SPARQL_REQUEST_HEADERS = {
  'Content-Type': 'application/sparql-query',
  'Accept': 'application/ld+json',
  'Ocp-Apim-Subscription-Key': $SPARQL_SUBSCRIPTION_KEY
}
$SPARQL_COUNT_HEADERS = {
  'Content-Type': 'application/sparql-query',
  'Accept': 'application/sparql-results+json',
  'Ocp-Apim-Subscription-Key': $SPARQL_SUBSCRIPTION_KEY
}

$DATE_DISPLAY_FORMAT = '%-d %B %Y'
$CSV_DATE_DISPLAY_FORMAT = '%-d/%m/%Y'
$DEFAULT_RESULTS_PER_PAGE = 20
$MAX_RESULTS_PER_PAGE = 250
