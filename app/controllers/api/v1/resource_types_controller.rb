# app/controllers/api/v1/resource_types_controller.rb
#
# Provides self-documenting endpoints for discovering available resource types.
# Returns metadata about each resource type including available fields,
# filters, sorting options, and example response structures.
#
# Endpoints:
#   GET /api/v1/resource-types          - List all resource types
#   GET /api/v1/resource-types/:id      - Documentation for a specific type
#
module Api
  module V1
    class ResourceTypesController < BaseController
      # Lists all available resource types with their URLs
      #
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

      # Returns detailed documentation for a single resource type,
      # including endpoints, parameters, filterable terms, field details,
      # and an example response structure.
      #
      # @param id [String] The resource type path (e.g., "research-briefings")
      #
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

      # Builds filter documentation from a model's term type mappings
      #
      # @param model_class [Class] The resource model class
      # @return [Array<Hash>] Filter descriptions with parameter name, label, and example
      #
      def build_filters_info(model_class)
        if model_class.const_defined?(:FILTER_MAPPINGS) && model_class::FILTER_MAPPINGS.any?
          # REST API resource - show filter params with allowed values
          model_class::FILTER_MAPPINGS.map do |key, mapping|
            info = {
              parameter: key.to_s,
              label: mapping[:label],
              example: "?#{key}=#{mapping[:values]&.first || 'value'}"
            }
            info[:values] = mapping[:values] if mapping[:values]
            info[:default] = mapping[:default] if mapping[:default]
            info
          end
        else
          # SPARQL resource - show term type mappings
          model_class::TERM_TYPE_MAPPINGS.map do |key, mapping|
            {
              parameter: key,
              label: mapping[:label],
              example: "?#{key}=12345"
            }
          end
        end
      end

      # Builds field documentation showing index fields, all fields,
      # and whether each field is simple or nested
      #
      # @param model_class [Class] The resource model class
      # @return [Hash] Field metadata including index_fields, all_fields, and field_details
      #
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

      # Builds an example response structure showing the shape of API responses
      #
      # @param model_class [Class] The resource model class
      # @return [Hash] Example response with meta, links, and items sections
      #
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

      # Builds an example item showing field names and types for index view
      #
      # @param model_class [Class] The resource model class
      # @return [Hash] Example item with placeholder values
      #
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
