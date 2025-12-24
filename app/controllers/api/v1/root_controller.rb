# app/controllers/api/v1/root_controller.rb
module Api
  module V1
    class RootController < BaseController
      def index
        render json: {
          name: "UK Parliament Data Library API",
          version: "v1",
          description: "API for accessing UK Parliament research publications and deposited papers",
          endpoints: build_endpoints,
          parameters: {
            page: "Page number (default: 1)",
            per_page: "Results per page (default: #{$DEFAULT_RESULTS_PER_PAGE}, max: #{$MAX_RESULTS_PER_PAGE})",
            fields: "Comma-separated list of fields to include, or 'all' for all fields"
          },
          source: "Data from UK Parliament SPARQL endpoint"
        }
      end

      private

      def build_endpoints
        endpoints = {}

        RESOURCE_CONFIG.each do |key, config|
          path = config[:route_path]
          endpoints[key] = {
            list: {
              url: "#{request.base_url}/api/v1/#{path}",
              method: "GET",
              description: "List all #{path.tr('-', ' ')}"
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
    end
  end
end
