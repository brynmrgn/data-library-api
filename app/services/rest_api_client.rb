# app/services/rest_api_client.rb
#
# Generic HTTP client for fetching data from REST APIs.
# Analogous to SparqlGetObject but for REST-sourced resources.
#
# Features:
#   - Paginated list fetching with Skip/Take translation
#   - Single item fetching by ID
#   - Response caching with configurable TTLs
#   - SSL support
#   - Array response handling for reference data endpoints
#
require 'digest'
require 'net/http'
require 'json'

class RestApiClient
  LIST_CACHE_TTL = 5.minutes
  SHOW_CACHE_TTL = 15.minutes

  # Fetches a paginated list of items from the upstream REST API.
  # Handles two response formats:
  #   - ResourceCollection: { items: [...], totalResults: N } (default)
  #   - Array: plain JSON array (for reference data endpoints with API_RESPONSE_FORMAT = 'array')
  #
  # @param model_class [Class] The RestApiResource subclass
  # @param query_params [Hash] Upstream API query parameters (from RestFilterBuilder)
  # @param limit [Integer] Number of items to fetch
  # @param offset [Integer] Pagination offset
  # @return [Hash] { items: [...], total: N, url: "..." }
  #
  def self.get_items(model_class, query_params: {}, limit:, offset:)
    array_response = model_class.const_defined?(:API_RESPONSE_FORMAT) && model_class::API_RESPONSE_FORMAT == 'array'

    # Array endpoints don't support Skip/Take — we fetch all and paginate ourselves
    params = if array_response
               query_params
             else
               query_params.merge('Skip' => offset.to_s, 'Take' => limit.to_s)
             end

    url = build_url(model_class::BASE_URL, model_class::API_PATH, params)
    cache_key = "rest/list/#{model_class.name.underscore}/#{Digest::MD5.hexdigest(url)}"

    result = Rails.cache.fetch(cache_key, expires_in: LIST_CACHE_TTL) do
      Rails.logger.debug { "[REST] get_items for #{model_class.name} (cache miss)" }
      fetch_json(url)
    end

    return { items: [], total: 0, url: url } unless result

    type_key = model_class.name.underscore.to_sym
    id_field = model_class::ID_FIELD

    raw_items = array_response ? result : (result['items'] || [])

    all_items = raw_items.filter_map do |item_data|
      id = item_data[id_field]
      next unless id

      model_class.new(id: id.to_s, data: item_data, resource_type: type_key)
    end

    if array_response
      # Apply our own pagination to the full array
      total = all_items.size
      items = all_items.slice(offset, limit) || []
      { items: items, total: total, url: url }
    else
      { items: all_items, total: result['totalResults'] || all_items.size, url: url }
    end
  end

  # Fetches a single item by ID from the upstream REST API.
  # For array-format resources (no /{id} endpoint), fetches the full array and finds by ID.
  #
  # @param model_class [Class] The RestApiResource subclass
  # @param id [String] Item ID
  # @return [Hash] { item: <RestApiResource>, url: "..." }
  #
  def self.get_item(model_class, id)
    if model_class.const_defined?(:API_RESPONSE_FORMAT) && model_class::API_RESPONSE_FORMAT == 'array'
      return get_item_from_array(model_class, id)
    end

    url = "#{model_class::BASE_URL}#{model_class::API_PATH}/#{id}"
    cache_key = "rest/item/#{model_class.name.underscore}/#{id}"

    result = Rails.cache.fetch(cache_key, expires_in: SHOW_CACHE_TTL) do
      Rails.logger.debug { "[REST] get_item for #{model_class.name} id=#{id} (cache miss)" }
      fetch_json(url)
    end

    return { item: nil, url: url } unless result

    type_key = model_class.name.underscore.to_sym
    item = model_class.new(
      id: result[model_class::ID_FIELD].to_s,
      data: result,
      resource_type: type_key
    )

    { item: item, url: url }
  end

  # Fetches a single item from an array-format endpoint by finding it in the full array.
  # Used for reference data endpoints that have no /{id} show endpoint.
  #
  def self.get_item_from_array(model_class, id)
    url = "#{model_class::BASE_URL}#{model_class::API_PATH}"
    cache_key = "rest/array/#{model_class.name.underscore}"

    result = Rails.cache.fetch(cache_key, expires_in: SHOW_CACHE_TTL) do
      Rails.logger.debug { "[REST] get_item_from_array for #{model_class.name} id=#{id} (cache miss)" }
      fetch_json(url)
    end

    return { item: nil, url: url } unless result

    id_field = model_class::ID_FIELD
    item_data = result.find { |d| d[id_field].to_s == id.to_s }
    return { item: nil, url: url } unless item_data

    type_key = model_class.name.underscore.to_sym
    item = model_class.new(id: item_data[id_field].to_s, data: item_data, resource_type: type_key)
    { item: item, url: "#{url}/#{id}" }
  end

  private

  # Builds a full URL with query parameters
  #
  def self.build_url(base_url, path, params)
    uri = URI("#{base_url}#{path}")
    uri.query = URI.encode_www_form(params) if params.any?
    uri.to_s
  end

  # Performs an HTTP GET and parses the JSON response
  #
  def self.fetch_json(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[REST] Request failed: #{response.code} for #{url}")
      return nil
    end

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error("[REST] Request error: #{e.message} for #{url}")
    nil
  end
end
