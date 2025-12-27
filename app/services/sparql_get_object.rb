# app/services/sparql_get_object.rb
#
# Fetches linked data resources from SPARQL endpoint.
# Handles both list (index) and single item (show) requests.
# Results are cached to reduce SPARQL endpoint load.
#
require 'digest'

class SparqlGetObject
  LIST_CACHE_TTL = 5.minutes
  SHOW_CACHE_TTL = 15.minutes
  # Fetches paginated list of items
  #
  # @param type_key [Symbol] Resource type (e.g., :research_briefing)
  # @param filter [String] SPARQL filter clause
  # @param limit [Integer] Number of items to fetch
  # @param offset [Integer] Pagination offset
  # @param all_fields [Boolean] Whether to fetch all fields or just index fields
  # @param sort_field [Symbol] Field to sort by
  # @param sort_order [Symbol] Sort direction (:asc or :desc)
  # @return [Hash] { items: [...], query: "..." }
  #
  def self.get_items(type_key, filter, limit:, offset:, all_fields: false, sort_field: nil, sort_order: nil)
    model_class = get_model_class(type_key)

    query = SparqlQueryBuilder.list_query(
      model_class,
      filter,
      limit: limit,
      offset: offset,
      all_fields: all_fields,
      sort_field: sort_field,
      sort_order: sort_order
    )

    # Build cache key from all query parameters
    cache_params = "#{filter}|#{limit}|#{offset}|#{all_fields}|#{sort_field}|#{sort_order}"
    cache_key = "sparql/list/#{type_key}/#{Digest::MD5.hexdigest(cache_params)}"

    results = Rails.cache.fetch(cache_key, expires_in: LIST_CACHE_TTL) do
      Rails.logger.debug { "[SPARQL] get_items for #{model_class.name} (cache miss)" }
      fetch_list_from_sparql(query, model_class)
    end

    return { items: [], query: query } if results.nil?

    { items: instantiate_items(results, type_key), query: query }
  end

  # Fetches list data from SPARQL endpoint (called on cache miss)
  #
  def self.fetch_list_from_sparql(query, model_class)
    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class
    )

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error { "[SPARQL] get_items failed: #{response.code}" }
      return nil
    end

    JSON.parse(response.body)
  end

  # Fetches a single item by ID
  #
  # @param type_key [Symbol] Resource type
  # @param id [String] Item ID
  # @return [Hash] { item: <LinkedDataResource>, query: "..." }
  #
  def self.get_item(type_key, id)
    model_class = get_model_class(type_key)

    item_uri = model_class.construct_uri(id)
    filter = "FILTER(?item = <#{item_uri}>)"

    query = SparqlQueryBuilder.show_query(model_class, filter)

    cache_key = "sparql/item/#{type_key}/#{id}"

    results = Rails.cache.fetch(cache_key, expires_in: SHOW_CACHE_TTL) do
      Rails.logger.debug { "[SPARQL] get_item for #{model_class.name} id=#{id} (cache miss)" }
      fetch_item_from_sparql(query, model_class)
    end

    return { item: nil, query: query } if results.nil?

    items = instantiate_items(results, type_key)

    { item: items.first, query: query }
  end

  # Fetches single item data from SPARQL endpoint (called on cache miss)
  #
  def self.fetch_item_from_sparql(query, model_class)
    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class
    )

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error { "[SPARQL] get_item failed: #{response.code} #{response.body}" }
      return nil
    end

    results = JSON.parse(response.body)

    # Wrap single item in @graph for consistency with get_items
    results = { "@graph" => [results] } unless results['@graph']

    results
  end

  private

  # Converts JSON-LD graph results into model instances
  #
  def self.instantiate_items(results, type_key)
    model_class = get_model_class(type_key)
    items_array = results['@graph'] || []

    items_array.filter_map do |result|
      next unless result['@id']

      model_class.new(
        id: result['@id'].split('/').last,
        data: result,
        resource_type: type_key
      )
    end
  end

  # Resolves type_key to model class
  #
  def self.get_model_class(type_key)
    class_name = type_key.to_s.classify
    model_class = class_name.constantize
    raise ArgumentError, "Unknown type: #{type_key}" unless model_class < LinkedDataResource
    model_class
  end
end
