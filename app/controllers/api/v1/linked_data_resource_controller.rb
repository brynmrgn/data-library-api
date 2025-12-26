# app/controllers/api/v1/linked_data_resource_controller.rb
#
# LinkedDataResourceController handles list (index) and detail (show) views for all
# linked data resource types, delegating formatting and filtering to services
#
module Api
  module V1
    class LinkedDataResourceController < BaseController
      include SparqlHttpHelper
      include SparqlItemsCount

      before_action :setup_model_and_type, only: %i[index show]

      # Returns a paginated list of items, optionally filtered by taxonomy terms
      #
      def index
        # Build filter clause
        filter = SparqlFilterBuilder.new(@model_class, params).build

        # Determine if all fields are requested
        all_fields = params[:fields] == 'all'

        # Set up pagination
        items_per_page = parse_items_per_page
        page = parse_page_number
        count = SparqlItemsCount.get_items_count(@type_key, filter)
        @pagy = Pagy.new(count: count, limit: items_per_page, page: page)

        # Fetch items
        result = SparqlGetObject.get_items(
          @type_key,
          filter,
          limit: items_per_page,
          offset: @pagy.offset,
          all_fields: all_fields
        )
        @items = result[:items]

        # Build and render response
        render json: {
          meta: PaginationBuilder.build_metadata(@pagy, @model_class, @items.size),
          links: build_pagination_links,
          items: JsonFormatterService.format_items_for_index(@items, all_fields: all_fields),
          queries: [result[:query]]
        }
      rescue ArgumentError => e
        render plain: e.message, status: :not_found
      end

      # Returns detailed information for a single item
      #
      def show
        result = SparqlGetObject.get_item(@type_key, params[:id])

        unless result[:item]
          render plain: 'Item not found', status: :not_found and return
        end

        render json: JsonFormatterService.format_item_for_show(result[:item]).merge(queries: [result[:query]])
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
