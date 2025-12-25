# app/controllers/api/v1/resource_types_controller.rb
module Api
  module V1
    class ResourceTypesController < BaseController
      def index
        render json: {
          resource_types: RESOURCE_CONFIG.map do |path, config|
            {
              id: path,
              url: "#{request.base_url}/api/v1/#{path}",
              documentation: "#{request.base_url}/api/v1/resource-types/#{path}"
            }
          end
        }
      end

      def show
        path = params[:id]
        config = RESOURCE_CONFIG[path]

        unless config
          render json: { error: "Unknown resource type: #{params[:id]}" }, status: :not_found
          return
        end

        model_class = config[:model_class].constantize

        render json: {
          id: path,
          endpoints: {
            list: {
              url: "#{request.base_url}/api/v1/#{path}",
              method: "GET",
              description: "Returns paginated list of #{path.tr('-', ' ')}"
            },
            show: {
              url: "#{request.base_url}/api/v1/#{path}/:id",
              method: "GET",
              description: "Returns a single #{path.tr('-', ' ').singularize} by ID"
            }
          },
          parameters: {
            page: "Page number (default: 1)",
            per_page: "Results per page (default: #{$DEFAULT_RESULTS_PER_PAGE}, max: #{$MAX_RESULTS_PER_PAGE})",
            fields: "Use 'all' to include all fields (default: index fields only)"
          },
          filters: build_filters_info(model_class),
          fields: build_fields_info(model_class),
          example_response: build_example_response(model_class)
        }
      end

      private

      def build_filters_info(model_class)
        model_class::TERM_TYPE_MAPPINGS.map do |key, mapping|
          {
            parameter: key,
            label: mapping[:label],
            example: "?#{key}=12345"
          }
        end
      end

      def build_fields_info(model_class)
        {
          index_fields: model_class::INDEX_ATTRIBUTES,
          all_fields: model_class::ATTRIBUTES.keys,
          field_details: model_class::ATTRIBUTES.map do |name, config|
            if config.is_a?(Hash)
              {
                name: name,
                type: "nested",
                properties: config[:properties].keys
              }
            else
              {
                name: name,
                type: "simple"
              }
            end
          end
        }
      end

      def build_example_response(model_class)
        {
          meta: {
            total_count: "integer",
            page: "integer",
            per_page: "integer",
            total_pages: "integer"
          },
          links: {
            self: "string (current page URL)",
            first: "string",
            last: "string",
            next: "string or null",
            prev: "string or null"
          },
          items: [
            build_example_item(model_class)
          ]
        }
      end

      def build_example_item(model_class)
        example = { id: "string", uri: "string" }

        model_class::INDEX_ATTRIBUTES.each do |attr|
          config = model_class::ATTRIBUTES[attr]
          if config.is_a?(Hash)
            nested = { id: "string" }
            config[:properties].each_key { |prop| nested[prop] = "string" }
            example[attr] = [nested]
          else
            example[attr] = "string"
          end
        end

        example
      end
    end
  end
end
