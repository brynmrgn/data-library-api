# app/controllers/object_controller.rb
class ObjectController < ApplicationController
  include SparqlHttpHelper
  include SparqlItemsCount
  include TermsHelper

  
def index
  model_name = params[:controller_name].classify
  @model_class = model_name.constantize
  type_key = model_name.underscore.to_sym
  
  filter = ""
  @title = ""

  if params['term_type']
  term_label = helpers.get_term_label(params[:id])
  mappings = @model_class::TERM_TYPE_MAPPINGS
  mapping = mappings[params['term_type'].to_s]
  
  if mapping.nil?
    Rails.logger.error "Invalid term_type '#{params['term_type']}' for #{@model_class}"
    render plain: "Invalid filter type '#{params['term_type']}' for #{params[:controller_name]}", status: :not_found
    return
  end
  
  filter_type = mapping[:predicate]
  @title = ": #{mapping[:label]}: #{term_label}"
  
  # Handle nested predicates (like authors)
  if mapping[:nested]
    filter = "?item #{filter_type} ?authorResource . 
              ?authorResource #{mapping[:nested_predicate]} ?term . 
              FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
  else
    filter = "?item #{filter_type} ?term . 
              FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
  end
  
  @id = params[:id]
end

  items = params[:per_page].presence&.to_i || $DEFAULT_RESULTS_PER_PAGE
  items = $DEFAULT_RESULTS_PER_PAGE if items <= 0
  items = [items, $MAX_RESULTS_PER_PAGE].min
  page  = params[:page].to_i
  page  = 1 if page < 1

  count = SparqlItemsCount.get_items_count(type_key, filter)
  @pagy = Pagy.new(count: count, limit: items, page: page)

  # Build the query for display
  @query = @model_class.list_query(filter, offset: @pagy.offset, limit: $DEFAULT_RESULTS_PER_PAGE)  
  @queries = [@query]

  @items = SparqlGetObject.get_items(type_key, filter, limit: items, offset: @pagy.offset)  
  #render partial: 'shared/index'

  respond_to do |format|
    format.html { render partial: 'shared/index' }
    format.json { render json: index_json , pretty: true}
  end
end

def show
  controller_name = params[:controller_name]
  type_key = controller_name.singularize.underscore.to_sym
  id = params[:id]
  
  @item = SparqlGetObject.get_item(type_key, id)
  
  respond_to do |format|
    format.html { render :show }
    format.json { render json: json_show_response(@item) }
  end
end

def feed
  model_name = params[:controller_name].classify
  @model_class = model_name.constantize
  type_key = model_name.underscore.to_sym
  
  filter = ""
  @title = ""

  if params['term_type']
    term_label = helpers.get_term_label(params[:id])
    
    mappings = @model_class::TERM_TYPE_MAPPINGS
    mapping = mappings[params['term_type'].to_s]
    
    if mapping.nil?
      Rails.logger.error "Invalid term_type '#{params['term_type']}' for #{@model_class}"
      render plain: "Invalid filter type '#{params['term_type']}' for #{params[:controller_name]}", status: :not_found
      return
    end
    
    filter_type = mapping[:predicate]
    @title = " - #{mapping[:label]}: #{term_label}"
    
    filter = "?item #{filter_type} ?term . FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
  end

  # Use the same approach as index - no more module includes
  @items = SparqlGetObject.get_items(type_key, filter, limit: 50, offset: 0)
  
  render template: 'shared/feed', layout: false
end


private

  def get_model_class(type_key)
    model_class = type_key.to_s.classify.constantize
    raise ArgumentError, "Unknown type: #{type_key}" unless model_class < LinkedDataResource
    model_class
  end

def index_json
  {
    meta: {
      total: @pagy.count,
      page: @pagy.page,
      per_page: @pagy.limit,
      total_pages: @pagy.pages,
      items_in_response: @items.size,
      type: @model_class.name.underscore
    },
    links: {
      self: request.original_url,
      first: url_for(params.to_unsafe_h.merge(page: 1, only_path: false)),
      last: url_for(params.to_unsafe_h.merge(page: @pagy.pages, only_path: false)),
      next: @pagy.next ? url_for(params.to_unsafe_h.merge(page: @pagy.next, only_path: false)) : nil,
      prev: @pagy.prev ? url_for(params.to_unsafe_h.merge(page: @pagy.prev, only_path: false)) : nil
    }.compact,
    items: @items.map { |item| format_item_for_json(item) }
  }
end

def format_item_for_json(item)
  {
    id: item.id,
    type: item.class.name.underscore,
    title: item.data['dc-term:title'] || item.data['dc-term:identifier'],
    identifier: item.data['dc-term:identifier'],
    date: item.data['dc-term:date'],
    url: "#{request.base_url}/#{params[:controller_name]}/#{item.id}",
    data: item.data
  }
end

def json_show_response(item)
  response = {
    data: item.data,
    metadata: {
      id: item.id,
      type: item.resource_type,
      uri: item.data['@id']
    }
  }
  
  # Pretty print in development
  if Rails.env.development?
    JSON.pretty_generate(response)
  else
    response
  end
end

end