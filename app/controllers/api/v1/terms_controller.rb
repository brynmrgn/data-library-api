# app/controllers/api/v1/terms_controller.rb
require 'net/http'
require 'json'

module Api
  module V1
    class TermsController < ApplicationController
      SPARQL_ENDPOINT = 'https://data-odp.parliament.uk/sparql'.freeze

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

        # Get paginated terms (only numeric IDs, not uncontrolled terms)
        query = <<~SPARQL
          PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

          SELECT DISTINCT ?term ?label
          WHERE {
            ?term skos:prefLabel ?label .
            FILTER(REGEX(STR(?term), "^http://data.parliament.uk/terms/[0-9]+$"))
          }
          ORDER BY ?label
          LIMIT #{per_page}
          OFFSET #{offset}
        SPARQL

        response = sparql_request(query)
        bindings = response&.dig('results', 'bindings') || []

        items = bindings.map do |binding|
          uri = binding.dig('term', 'value')
          {
            id: uri&.split('/')&.last,
            uri: uri,
            label: binding.dig('label', 'value')
          }
        end

        {
          meta: {
            page: page,
            per_page: per_page
          },
          items: items
        }
      end

      def fetch_term(term_id)
        query = <<~SPARQL
          PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>

          SELECT ?termLabel ?firstName ?surname
          WHERE {
            VALUES ?item {
              <http://data.parliament.uk/terms/#{term_id}>
            }
            ?item skos:prefLabel ?termLabel .
            OPTIONAL { ?item foaf:firstName ?firstName . }
            OPTIONAL { ?item foaf:surname ?surname . }
          }
        SPARQL

        response = sparql_request(query)
        return nil unless response

        binding = response.dig('results', 'bindings', 0)
        return nil unless binding

        label = build_label(binding)
        return nil unless label

        {
          id: term_id,
          uri: "http://data.parliament.uk/terms/#{term_id}",
          label: label
        }
      end

      def build_label(binding)
        # Try foaf:firstName and foaf:surname first (for authors)
        if binding['firstName'] && binding['surname']
          first_name = binding['firstName']['value']
          surname = binding['surname']['value']
          "#{first_name} #{surname}"
        elsif binding['termLabel']
          term_label = binding['termLabel']['value']

          # If it looks like "Surname, Firstname", reverse it
          if term_label =~ /^(.+),\s*(.+)$/
            "#{$2} #{$1}"
          else
            term_label
          end
        end
      end

      def sparql_request(query)
        uri = URI(SPARQL_ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.verify_callback = ->(_preverify_ok, _store_ctx) { true }
        http.open_timeout = 5
        http.read_timeout = 10

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/sparql-query'
        request['Accept'] = 'application/sparql-results+json'
        request.body = query

        response = http.request(request)
        return nil unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue StandardError => e
        Rails.logger.error "SPARQL request failed: #{e.message}"
        nil
      end
    end
  end
end
