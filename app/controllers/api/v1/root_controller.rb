# app/controllers/api/v1/root_controller.rb
#
# API root endpoint. Returns an overview of the API including all available
# resource types, their endpoints, query parameters, and filtering options.
# Serves as the entry point for API discovery.
#
# Endpoint:
#   GET /api/v1
#
module Api
  module V1
    class RootController < BaseController
      # Returns API overview with available endpoints, parameters, and filtering info
      #
      def index
        render json: {
          name: "UK Parliament Data Library API",
          version: "v1",
          description: "API for accessing data from UK Parliament's data platforms.",
          documentation: "#{request.base_url}/api/v1/resource-types",
          endpoints: build_endpoints,
          parameters: {
            page: "Page number (default: 1)",
            per_page: "Results per page (default: #{$DEFAULT_RESULTS_PER_PAGE}, max: #{$MAX_RESULTS_PER_PAGE})",
            fields: "Comma-separated list of fields to include, or 'all' for all fields"
          },
          filtering: build_filtering_info,
          sources: [
            "UK Parliament SPARQL endpoint (research briefings, deposited papers)",
            "UK Parliament Committees API (committees)"
          ]
        }
      end

      private

      # Builds a hash of all available endpoints from RESOURCE_CONFIG,
      # including the terms endpoint
      #
      # @return [Hash] Endpoint descriptions keyed by resource path
      #
      def build_endpoints
        endpoints = {}

        RESOURCE_CONFIG.each do |path, config|
          model_class = config[:model_class].constantize

          # Use FILTER_MAPPINGS keys for REST resources, TERM_TYPE_MAPPINGS for SPARQL
          filter_keys = if model_class.const_defined?(:FILTER_MAPPINGS) && model_class::FILTER_MAPPINGS.any?
                          model_class::FILTER_MAPPINGS.keys.map(&:to_s)
                        else
                          model_class::TERM_TYPE_MAPPINGS.keys
                        end

          endpoints[path] = {
            list: {
              url: "#{request.base_url}/api/v1/#{path}",
              method: "GET",
              description: "List all #{path.tr('-', ' ')}",
              filterable_by: filter_keys
            },
            show: {
              url: "#{request.base_url}/api/v1/#{path}/:id",
              method: "GET",
              description: "Get a single #{path.tr('-', ' ').singularize} by ID"
            }
          }
        end

        # Add terms endpoint
        endpoints["terms"] = {
          list: {
            url: "#{request.base_url}/api/v1/terms",
            method: "GET",
            description: "List all parliamentary thesaurus terms"
          },
          show: {
            url: "#{request.base_url}/api/v1/terms/:id",
            method: "GET",
            description: "Get a single term by ID"
          }
        }

        endpoints
      end

      # Builds filtering documentation showing how to filter results by
      # taxonomy terms, with examples and available term types per resource
      #
      # @return [Hash] Filtering description, format, examples, and term types
      #
      def build_filtering_info
        {
          description: "Filter results using query parameters (multiple filters supported)",
          format: "/api/v1/:resource?:term_type=:term_id",
          examples: [
            "#{request.base_url}/api/v1/research-briefings?topic=123",
            "#{request.base_url}/api/v1/research-briefings?topic=123&publisher=456",
            "#{request.base_url}/api/v1/committees?house=Commons"
          ],
          filters_by_resource: RESOURCE_CONFIG.transform_values do |config|
            model_class = config[:model_class].constantize
            if model_class.const_defined?(:FILTER_MAPPINGS) && model_class::FILTER_MAPPINGS.any?
              model_class::FILTER_MAPPINGS.transform_values { |v| v[:label] }
            else
              model_class::TERM_TYPE_MAPPINGS.transform_values { |v| v[:label] }
            end
          end
        }
      end
    end
  end
end
