# app/controllers/api/v1/root_controller.rb
module Api
  module V1
    class RootController < BaseController
      def index
        render json: {
          name: "UK Parliament Data Library API",
          version: "v1",
          description: "API for accessing UK Parliament research publications and deposited papers",
          documentation: "#{request.base_url}/api/v1/resource-types",
          endpoints: build_endpoints,
          parameters: {
            page: "Page number (default: 1)",
            per_page: "Results per page (default: #{$DEFAULT_RESULTS_PER_PAGE}, max: #{$MAX_RESULTS_PER_PAGE})",
            fields: "Comma-separated list of fields to include, or 'all' for all fields"
          },
          filtering: build_filtering_info,
          source: "Data from UK Parliament SPARQL endpoint"
        }
      end

      private

      def build_endpoints
        endpoints = {}

        RESOURCE_CONFIG.each do |path, config|
          model_class = config[:model_class].constantize
          term_types = model_class::TERM_TYPE_MAPPINGS.keys

          endpoints[path] = {
            list: {
              url: "#{request.base_url}/api/v1/#{path}",
              method: "GET",
              description: "List all #{path.tr('-', ' ')}",
              filterable_by: term_types
            },
            show: {
              url: "#{request.base_url}/api/v1/#{path}/:id",
              method: "GET",
              description: "Get a single #{path.tr('-', ' ').singularize} by ID"
            }
          }
        end

        endpoints
      end

      def build_filtering_info
        {
          description: "Filter results using query parameters (multiple filters supported)",
          format: "/api/v1/:resource?:term_type=:term_id",
          examples: [
            "#{request.base_url}/api/v1/research-briefings?topic=123",
            "#{request.base_url}/api/v1/research-briefings?topic=123&publisher=456"
          ],
          term_types_by_resource: RESOURCE_CONFIG.transform_values do |config|
            model_class = config[:model_class].constantize
            model_class::TERM_TYPE_MAPPINGS.transform_values { |v| v[:label] }
          end
        }
      end
    end
  end
end
