# app/services/search_service.rb
#
# Executes full-text search queries against the Elasticsearch index.
# Returns results in a format consistent with the existing API response structure.
#
class SearchService
  INDEX_NAME = SearchIndexService::INDEX_NAME

  # @param query [String] Search query
  # @param type [String, nil] Optional resource type filter
  # @param filters [Hash] Optional taxonomy filters (e.g. { 'topic' => '12345' })
  # @param page [Integer] Page number (1-based)
  # @param per_page [Integer] Results per page
  # @return [Hash] Response with meta, links, and items
  #
  def self.search(query:, type: nil, filters: {}, page: 1, per_page: 20)
    from = (page - 1) * per_page

    es_body = {
      from: from,
      size: per_page,
      query: build_query(query, type, filters),
      highlight: {
        fields: {
          title: { number_of_fragments: 0 },
          description: { fragment_size: 200, number_of_fragments: 1 },
          summary: { fragment_size: 200, number_of_fragments: 1 },
          topics: { number_of_fragments: 0 },
          subjects: { number_of_fragments: 0 }
        },
        pre_tags: ['<em>'],
        post_tags: ['</em>']
      },
      sort: [
        { _score: :desc },
        { date: { order: :desc, unmapped_type: :date } }
      ]
    }

    response = ELASTICSEARCH_CLIENT.search(index: INDEX_NAME, body: es_body)
    format_response(response, query, page, per_page)
  end

  private

  def self.build_query(query, type, filters)
    must = {
      multi_match: {
        query: query,
        fields: %w[title^3 description^1.5 identifier.text summary topics subjects publisher],
        type: 'best_fields',
        fuzziness: 'AUTO'
      }
    }

    # Build filter clauses
    filter_clauses = []
    filter_clauses << { term: { resource_type: type } } if type.present?

    filters.each do |param_name, term_id|
      es_field = SearchIndexService::FILTER_PARAMS[param_name.to_s]
      filter_clauses << { term: { es_field => term_id.to_s } } if es_field
    end

    if filter_clauses.any?
      {
        bool: {
          must: must,
          filter: filter_clauses
        }
      }
    else
      must
    end
  end

  def self.format_response(response, query, page, per_page)
    total = response.dig('hits', 'total', 'value') || 0
    total_pages = (total.to_f / per_page).ceil

    items = response['hits']['hits'].map do |hit|
      source = hit['_source']
      highlight = hit['highlight'] || {}

      {
        id: source['resource_id'],
        resource_type: source['resource_type'],
        title: source['title'],
        description: source['description'],
        identifier: source['identifier'],
        date: source['date'],
        score: hit['_score'],
        highlight: highlight.transform_keys(&:to_s)
      }
    end

    {
      meta: {
        total_count: total,
        page: page,
        per_page: per_page,
        total_pages: total_pages,
        query: query
      },
      items: items
    }
  end
end
