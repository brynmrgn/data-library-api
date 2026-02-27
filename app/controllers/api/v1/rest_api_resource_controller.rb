# app/controllers/api/v1/rest_api_resource_controller.rb
#
# Generic controller for all REST API-sourced resource types.
# Parallels LinkedDataResourceController but fetches from upstream REST APIs
# instead of SPARQL endpoints.
#
# Routes are configured dynamically based on RESOURCE_CONFIG (see config/routes.rb).
#
# Endpoints:
#   GET /api/v1/:resource_type          - Paginated list with filtering
#   GET /api/v1/:resource_type/:id      - Single item detail
#
# Query parameters:
#   page      - Page number (default: 1)
#   per_page  - Items per page (default: 20, max: 250)
#   fields    - Use 'all' for complete data, otherwise index fields only
#   <filter>  - Filter by upstream API params (e.g., ?house=Commons)
#
module Api
  module V1
    class RestApiResourceController < BaseController
      before_action :setup_model_and_type, only: %i[index show]

      # Returns a paginated list of items, optionally filtered
      #
      def index
        expires_in 5.minutes, public: true

        # Build upstream query params from filters
        filter_params = RestFilterBuilder.new(@model_class, params).build

        # Pagination
        items_per_page = parse_items_per_page
        page = parse_page_number
        offset = (page - 1) * items_per_page

        # Determine if all fields are requested
        all_fields = params[:fields] == 'all'

        # Fetch items from upstream API
        result = RestApiClient.get_items(
          @model_class,
          query_params: filter_params,
          limit: items_per_page,
          offset: offset
        )

        # Build Pagy object from upstream total
        @pagy = Pagy.new(count: result[:total], limit: items_per_page, page: page)

        render json: {
          meta: PaginationBuilder.build_metadata(@pagy, @model_class, result[:items].size).merge(
            sort: {
              field: @model_class::DEFAULT_SORT_FIELD.to_s,
              order: @model_class::DEFAULT_SORT_ORDER.to_s,
              sortable_fields: @model_class::SORTABLE_FIELDS.map(&:to_s)
            },
            upstream_url: result[:url]
          ),
          links: build_pagination_links,
          items: JsonFormatterService.format_items_for_index(result[:items], all_fields: all_fields)
        }
      end

      # Returns detailed information for a single item
      #
      def show
        expires_in 15.minutes, public: true

        result = RestApiClient.get_item(@model_class, params[:id])

        unless result[:item]
          render plain: 'Item not found', status: :not_found and return
        end

        response = JsonFormatterService.format_item_for_show(result[:item])
        response[:meta][:upstream_url] = result[:url]
        render json: response
      end

      private

      # Sets up model class and type key from route parameters
      #
      def setup_model_and_type
        model_name = params[:controller_name].classify
        @model_class = model_name.constantize
        @type_key = model_name.underscore.to_sym
      end

      # Parses and validates items per page parameter
      #
      def parse_items_per_page
        items = params[:per_page].presence&.to_i || $DEFAULT_RESULTS_PER_PAGE
        items = $DEFAULT_RESULTS_PER_PAGE if items <= 0
        [items, $MAX_RESULTS_PER_PAGE].min
      end

      # Parses and validates page number parameter
      #
      def parse_page_number
        page = params[:page].to_i
        page < 1 ? 1 : page
      end

      # Builds pagination links using request path
      #
      def build_pagination_links
        base_url = "#{request.base_url}#{request.path}"
        query_params = request.query_parameters.except('page')

        {
          self: request.original_url,
          first: build_page_url(base_url, query_params, 1),
          last: build_page_url(base_url, query_params, @pagy.pages),
          next: @pagy.next ? build_page_url(base_url, query_params, @pagy.next) : nil,
          prev: @pagy.prev ? build_page_url(base_url, query_params, @pagy.prev) : nil
        }.compact
      end

      def build_page_url(base_url, query_params, page)
        params = query_params.merge(page: page)
        "#{base_url}?#{params.to_query}"
      end
    end
  end
end
