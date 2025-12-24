# app/controllers/api/v1/object_controller.rb
#
# ObjectController handles list (index) and detail (show) views for all
# linked data resource types, delegating formatting and filtering to services
#
module Api
  module V1
    class ObjectController < BaseController
      include SparqlHttpHelper
      include SparqlItemsCount
      include TermsHelper

      before_action :setup_model_and_type, only: %i[index show]

      # Returns a paginated list of items, optionally filtered by taxonomy terms
      #
      def index
        # Build filter clause
        filter_builder = SparqlFilterBuilder.new(@model_class, params, helpers).build
        filter = filter_builder.filter
        @title = filter_builder.title

        # Determine which attributes to include
        attributes_to_include = determine_attributes

        # Set up pagination
        items_per_page = parse_items_per_page
        page = parse_page_number
        count = SparqlItemsCount.get_items_count(@type_key, filter)
        @pagy = Pagy.new(count: count, limit: items_per_page, page: page)

        # Fetch items
        @items = SparqlGetObject.get_items(
          @type_key,
          filter,
          limit: items_per_page,
          offset: @pagy.offset,
          attributes: attributes_to_include
        )

        # Build and render response
        render json: {
          meta: PaginationBuilder.build_metadata(@pagy, @model_class, @items.size),
          links: build_pagination_links,
          items: JsonFormatterService.format_items_for_index(@items, attributes: attributes_to_include)
        }
      rescue ArgumentError => e
        render plain: e.message, status: :not_found
      end

      # Returns detailed information for a single item
      #
      def show
        item = SparqlGetObject.get_item(@type_key, params[:id], attributes: @model_class::ATTRIBUTES.keys)

        unless item
          render plain: 'Item not found', status: :not_found and return
        end

        render json: JsonFormatterService.format_item_for_show(item)
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

      # Builds pagination links using URL helpers
      #
      def build_pagination_links
        {
          self: request.original_url,
          first: url_for(params.to_unsafe_h.merge(page: 1, only_path: false)),
          last: url_for(params.to_unsafe_h.merge(page: @pagy.pages, only_path: false)),
          next: @pagy.next ? url_for(params.to_unsafe_h.merge(page: @pagy.next, only_path: false)) : nil,
          prev: @pagy.prev ? url_for(params.to_unsafe_h.merge(page: @pagy.prev, only_path: false)) : nil
        }.compact
      end

      def determine_attributes
        # Handle ?fields= parameter
        if params[:fields] == 'all'
          # Explicitly request all attributes
          @model_class::ATTRIBUTES.keys
        elsif params[:fields].present?
          # Specific fields requested
          parse_fields_param(params[:fields], @model_class)
        else
          # Default behavior based on action
          if action_name == 'show'
            @model_class::ATTRIBUTES.keys
          else # index
            @model_class::INDEX_ATTRIBUTES
          end
        end
      end

      def parse_fields_param(fields_string, model_class)
        requested = fields_string.split(',').map(&:strip).map(&:to_sym)
        available = model_class::ATTRIBUTES.keys

        # Only return valid attributes
        requested & available
      end
    end
  end
end
