# app/controllers/api/v1/search_controller.rb
#
# Full-text search endpoint.
#
# GET /api/v1/search?q=...&type=...&topic=...&subject=...&page=...&per_page=...
#
#   q        - Search query (required)
#   type     - Filter by resource type: research_briefing, deposited_paper (optional)
#   topic, subject, publisher, section, subtype, category,
#   depositing-department, corporate-author, legislature
#            - Filter by taxonomy term ID (optional, combinable)
#   page     - Page number, default 1
#   per_page - Results per page, default 20, max 100
#
module Api
  module V1
    class SearchController < BaseController
      def index
        query = params[:q].to_s.strip
        if query.blank?
          render json: { error: 'Query parameter q is required' }, status: :bad_request
          return
        end

        page = [params[:page].to_i, 1].max
        per_page = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 20

        # Extract taxonomy filters
        filters = {}
        SearchIndexService::FILTER_PARAMS.each_key do |param_name|
          filters[param_name] = params[param_name] if params[param_name].present?
        end

        results = SearchService.search(
          query: query,
          type: params[:type].presence,
          filters: filters,
          page: page,
          per_page: per_page
        )

        expires_in 5.minutes, public: true
        render json: results
      end
    end
  end
end
