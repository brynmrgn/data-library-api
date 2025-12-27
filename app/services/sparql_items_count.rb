# app/services/sparql_items_count.rb
#
# Gets total item count for pagination.
# Executes a COUNT query against the SPARQL endpoint.
# Results are cached for 10 minutes to reduce SPARQL endpoint load.
#
# Respects both:
#   - User-provided filters (e.g., ?topic=123)
#   - Model's REQUIRED_FILTER (e.g., status = published)
#
module SparqlItemsCount
  include SparqlHttpHelper
  require 'cgi'
  require 'digest'

  CACHE_TTL = 10.minutes

  # Returns total count of items matching the filter
  #
  # @param type_key [Symbol] Resource type (e.g., :research_briefing)
  # @param filter [String] Optional SPARQL filter clause
  # @return [Integer] Total count
  #
  def self.get_items_count(type_key, filter = "")
    cache_key = "sparql/count/#{type_key}/#{Digest::MD5.hexdigest(filter.to_s)}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      fetch_count_from_sparql(type_key, filter)
    end
  end

  private

  def self.fetch_count_from_sparql(type_key, filter)
    model_class = get_model_class(type_key)
    item_type = model_class::SPARQL_TYPE
    required_filter = build_required_filter_clause(model_class)

    query = <<~SPARQL
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX dc-term: <http://purl.org/dc/terms/>
      PREFIX parl: <http://data.parliament.uk/schema/parl#>
      SELECT (COUNT(DISTINCT ?item) AS ?total)
      WHERE {
        ?item a #{item_type} .
        #{required_filter}#{filter}
      }
    SPARQL

    Rails.logger.debug { "[SPARQL] Count query for #{type_key} (cache miss)" }

    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_COUNT_HEADERS
    )

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("SPARQL count request failed: #{response.code} #{response.body}")
      return 0
    end

    data = JSON.parse(response.body)
    data["results"]["bindings"][0]["total"]["value"].to_i
  end

  def self.get_model_class(type_key)
    model_class = type_key.to_s.classify.constantize
    raise ArgumentError, "Unknown type: #{type_key}" unless model_class < LinkedDataResource
    model_class
  end

  # Builds SPARQL filter clause from model's REQUIRED_FILTER constant
  # Returns empty string if no required filter defined
  #
  def self.build_required_filter_clause(model_class)
    return '' unless model_class.const_defined?(:REQUIRED_FILTER) && model_class::REQUIRED_FILTER

    filter_config = model_class::REQUIRED_FILTER
    predicate = filter_config[:predicate]
    value = filter_config[:value].to_s.downcase

    <<~SPARQL
      ?item #{predicate} ?_rf_value .
      FILTER(LCASE(STR(?_rf_value)) = "#{value}")
    SPARQL
  end
end