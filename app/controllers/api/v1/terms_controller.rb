# app/controllers/api/v1/terms_controller.rb
#
# Controller for parliamentary thesaurus terms (SES concepts).
# Terms are used for filtering resources by topic, subject, publisher, etc.
#
module Api
  module V1
    class TermsController < BaseController
      # Headers for SPARQL SELECT queries (not CONSTRUCT)
      SPARQL_SELECT_HEADERS = {
        'Content-Type' => 'application/sparql-query',
        'Accept' => 'application/sparql-results+json'
      }.freeze

      # Cache the total count (it rarely changes)
      TERMS_COUNT_CACHE_KEY = 'terms_total_count'.freeze
      TERMS_COUNT_CACHE_TTL = 1.hour

      def index
        page = [params[:page].to_i, 1].max
        per_page = [[params[:per_page].to_i, 1].max, 250].min
        per_page = 20 if params[:per_page].blank?

        terms = fetch_all_terms(page, per_page)

        render json: terms
      end

      def show
        term_id = params[:id]
        term_data = fetch_term(term_id)

        if term_data
          render json: term_data
        else
          render json: { error: 'Term not found' }, status: :not_found
        end
      end

      private

      def fetch_all_terms(page, per_page)
        offset = (page - 1) * per_page

        # Get total count (cached)
        total = Rails.cache.fetch(TERMS_COUNT_CACHE_KEY, expires_in: TERMS_COUNT_CACHE_TTL) do
          fetch_terms_count
        end

        query = Term.index_query(limit: per_page, offset: offset)
        response = sparql_select_request(query)
        bindings = response&.dig('results', 'bindings') || []

        items = bindings.map do |binding|
          uri = binding.dig('term', 'value')
          {
            id: uri&.split('/')&.last,
            uri: uri,
            label: build_label(binding)
          }
        end

        {
          meta: {
            total: total,
            page: page,
            per_page: per_page,
            total_pages: total ? (total.to_f / per_page).ceil : nil
          },
          items: items,
          queries: [query]
        }
      end

      def fetch_terms_count
        response = sparql_select_request(Term::COUNT_QUERY)
        response&.dig('results', 'bindings', 0, 'count', 'value').to_i
      rescue
        nil
      end

      def fetch_term(term_id)
        query = Term.show_query(term_id)
        response = sparql_select_request(query)
        return nil unless response

        bindings = response.dig('results', 'bindings')
        return nil if bindings.blank?

        # Convert predicate/object pairs to a hash
        data = {}
        bindings.each do |binding|
          predicate = binding.dig('predicate', 'value')
          object = binding.dig('object', 'value')
          data[predicate] = object if predicate && object
        end

        term = Term.new(id: term_id, data: data)
        term.to_h.merge(queries: [query])
      end

      def build_label(binding)
        # Try foaf:firstName and foaf:surname first (for authors)
        if binding['firstName'] && binding['surname']
          first_name = binding['firstName']['value']
          surname = binding['surname']['value']
          "#{first_name} #{surname}"
        elsif binding['prefLabel']
          pref_label = binding['prefLabel']['value']

          # If it looks like "Surname, Firstname", reverse it
          if pref_label =~ /^(.+),\s*(.+)$/
            "#{$2} #{$1}"
          else
            pref_label
          end
        end
      end

      # Execute a SPARQL SELECT query (returns JSON results, not RDF)
      #
      def sparql_select_request(query)
        response = SparqlHttpHelper.execute_sparql_post(
          $SPARQL_REQUEST_URI,
          query,
          SPARQL_SELECT_HEADERS
        )
        return nil unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue StandardError => e
        Rails.logger.error "[SPARQL] Terms request failed: #{e.message}"
        nil
      end
    end
  end
end
