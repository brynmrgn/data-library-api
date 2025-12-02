#require 'pagy'
class ResearchBriefingsController < ApplicationController

  include Sparql::Get::ResearchBriefings
  include Sparql::Queries::ResearchBriefings
  include Sparql::Get::ResearchBriefing
  include Sparql::Get::Response
  #include Pagy::Backend
  #include PagySparql

  def index
    filter = ""
    @title = ": all"

    if params['term_type']
      term_label = helpers.get_term_label(params[:id])
      case params['term_type']
      when 'subject'
        filter_type = "dc-term:subject"
        @title = ": subject: #{term_label}"
      when 'topic'
        filter_type = "<http://data.parliament.uk/schema/parl#topic>"
        @title = ": topic: #{term_label}"
      when 'publisher'
        filter_type = "dc-term:publisher"
        @title = ": published by: #{term_label}"
      end

      filter = "?item #{filter_type} ?term .
      FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
      @id = params[:id]
    end

    items = params[:per_page].presence&.to_i || $DEFAULT_RESULTS_PER_PAGE
    items = $DEFAULT_RESULTS_PER_PAGE if items <= 0
    items = [items, $MAX_RESULTS_PER_PAGE].min
    page  = params[:page].to_i
    page  = 1 if page < 1

    total = get_items_count(filter)

    @pagy = Pagy.new(count: total, limit: $DEFAULT_RESULTS_PER_PAGE, page: page)

    @items = get_items(
      filter,
      limit:  $DEFAULT_RESULTS_PER_PAGE, 
      offset: @pagy.offset
    )
  end

  def show
    @item = get_item(params[:id])
    #@query = deposited_papers_query(params[:id])
  end

end