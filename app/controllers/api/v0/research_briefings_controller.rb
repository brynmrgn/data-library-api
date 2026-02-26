# app/controllers/api/v0/research_briefings_controller.rb
#
# LDA compatibility controller for research briefings.
# Accepts LDA-style query parameters and returns LDA-format responses.
#
# Endpoints:
#   GET /api/v0/research-briefings          - Paginated list
#   GET /api/v0/research-briefings/:id      - Single item
#
# Query parameters:
#   _page      - Page number, zero-indexed (default: 0)
#   _pageSize  - Items per page (default: 10, max: 500)
#   <term>     - Filter by taxonomy term (e.g., ?topic=12345)
#
module Api
  module V0
    class ResearchBriefingsController < BaseController
      include SparqlHttpHelper
      include SparqlItemsCount

      LDA_DEFAULT_PAGE_SIZE = 10
      LDA_MAX_PAGE_SIZE = 500

      def index
        expires_in 5.minutes, public: true

        filter = SparqlFilterBuilder.new(ResearchBriefing, params).build

        sort_field, sort_order = parse_sort_params
        items_per_page = parse_page_size
        lda_page = parse_lda_page
        pagy_page = lda_page + 1 # Pagy is 1-indexed, LDA is 0-indexed

        count = SparqlItemsCount.get_items_count(:research_briefing, filter)
        @pagy = Pagy.new(count: count, limit: items_per_page, page: pagy_page)

        result = SparqlGetObject.get_items(
          :research_briefing,
          filter,
          limit: items_per_page,
          offset: @pagy.offset,
          all_fields: true,
          sort_field: sort_field,
          sort_order: sort_order
        )

        lda_items = LdaFormatterService.format_items(result[:items])

        render json: LdaFormatterService.build_list_envelope(
          items: lda_items,
          total: count,
          page: lda_page,
          page_size: items_per_page,
          request: request
        )
      rescue ArgumentError => e
        render plain: e.message, status: :not_found
      end

      def show
        expires_in 15.minutes, public: true

        result = SparqlGetObject.get_item(:research_briefing, params[:id])

        unless result[:item]
          render plain: 'Item not found', status: :not_found and return
        end

        lda_item = LdaFormatterService.format_item(result[:item])
        lda_item["isPrimaryTopicOf"] = request.original_url

        render json: LdaFormatterService.build_show_envelope(
          item: lda_item,
          request: request
        )
      end

      private

      def parse_lda_page
        page = params[:_page].to_i
        page < 0 ? 0 : page
      end

      def parse_page_size
        size = params[:_pageSize].presence&.to_i || LDA_DEFAULT_PAGE_SIZE
        size = LDA_DEFAULT_PAGE_SIZE if size <= 0
        [size, LDA_MAX_PAGE_SIZE].min
      end

      def parse_sort_params
        sort_field = params[:_sort].presence&.to_sym
        sort_order = params[:_orderBy].presence&.to_sym

        if sort_field && !ResearchBriefing::SORTABLE_FIELDS.include?(sort_field)
          raise ArgumentError, "Invalid sort field '#{sort_field}'. Valid fields: #{ResearchBriefing::SORTABLE_FIELDS.join(', ')}"
        end

        if sort_order && !%i[asc desc].include?(sort_order)
          raise ArgumentError, "Invalid sort order '#{sort_order}'. Valid orders: asc, desc"
        end

        [sort_field, sort_order]
      end
    end
  end
end
