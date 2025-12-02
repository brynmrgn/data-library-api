#require 'pagy'
class DepositedPapersController < ApplicationController

  include Sparql::Get::DepositedPapers
  include Sparql::Queries::DepositedPapers
  include Sparql::Get::DepositedPaper
  include Sparql::Get::Response

  #include Pagy::Backend

  def index
    filter = ""
    @title = ": all"

    if params['term_type']
      term_label = helpers.get_term_label(params[:id])
      case params['term_type']
      when 'legislature'
        filter_type = "<http://data.parliament.uk/schema/parl#legislature>"
        @title = ": deposited in: #{term_label}"
      when 'subject'
        filter_type = "dc-term:subject"
        @title = ": subject: #{term_label}"
      when 'corporate-author'
        filter_type = "<http://data.parliament.uk/schema/parl#corporateAuthor>"
        @title = ": author: #{term_label}"
      when 'depositing-department'
        filter_type = "<http://data.parliament.uk/schema/parl#department>"
        @title = ": deposited by: #{term_label}"
      end

      filter = "?depositedPaper #{filter_type} ?term .
      FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
      @id = params[:id]
    end

    items = params[:per_page].presence&.to_i || $DEFAULT_RESULTS_PER_PAGE
    items = $DEFAULT_RESULTS_PER_PAGE if items <= 0
    items = [items, $MAX_RESULTS_PER_PAGE].min
    page  = params[:page].to_i
    page  = 1 if page < 1

    total = get_items_count(filter)

    # Use 'items' instead of hardcoded $DEFAULT_RESULTS_PER_PAGE
    @pagy = Pagy.new(count: total, limit: items, page: page)

    @items = get_items(
      filter,
      limit:  items,  # Use the calculated items value
      offset: @pagy.offset
    )
  end

  def show
    @item = get_item(params[:id])
    #@query = deposited_papers_query(params[:id])
  end

end