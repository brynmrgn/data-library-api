# app/controllers/object_controller.rb
class ObjectController < ApplicationController
  include Sparql::Get::Response
  include SparqlItemsCount

  
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
    filter = "?item #{filter_type} ?term . FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
    @id = params[:id]
  end

  items = params[:per_page].presence&.to_i || $DEFAULT_RESULTS_PER_PAGE
  items = $DEFAULT_RESULTS_PER_PAGE if items <= 0
  items = [items, $MAX_RESULTS_PER_PAGE].min
  page  = params[:page].to_i
  page  = 1 if page < 1

  count = SparqlItemsCount.get_items_count(type_key, filter)
  @pagy = Pagy.new(count: count, limit: $DEFAULT_RESULTS_PER_PAGE, page: page)

  # Build the query for display
  query_module = @model_class::QUERY_MODULE
  @query = query_module.list_query(filter, offset: @pagy.offset, limit: $DEFAULT_RESULTS_PER_PAGE)
  @queries = [@query]

  @items = SparqlGetObject.get_items(type_key, filter, limit: $DEFAULT_RESULTS_PER_PAGE, offset: @pagy.offset)
  
  render partial: 'shared/index'

  respond_to do |format|
    format.html
    format.json { render json: index_json }
  end
end

def show
  @type_key = params[:controller_name].underscore.to_sym
  @model_class = get_model_class(@type_key)

  puts "DEBUG type_key: #{@type_key}"
  puts "DEBUG model_class: #{@model_class}"
  puts "DEBUG params[:id]: #{params[:id]}"
  puts "DEBUG constructed_uri: #{@model_class.construct_uri(params[:id])}"
  
  @item = SparqlGetObject.get_item(@type_key, params[:id])

  puts "DEBUG @item: #{@item.inspect}"
  puts "DEBUG @item.class: #{@item.class}"
  
  render "object/#{params[:controller_name]}_show"
end

def feed
  model_name = params[:controller_name].classify
  @model_class = model_name.constantize
  
  # Get the module instances
  items_module = "Sparql::Get::#{model_name.pluralize}".constantize
  queries_module = "Sparql::Queries::#{model_name.pluralize}".constantize
  
  # Extend self with the modules
  self.class.include(items_module)
  self.class.include(queries_module)
  
  filter = ""
  @title = ""

  if params['term_type']
    term_label = helpers.get_term_label(params[:id])
    
    mappings = @model_class::TERM_TYPE_MAPPINGS
    mapping = mappings[params['term_type'].to_s]
    
    if mapping.nil?
      render plain: "Invalid filter type", status: :not_found
      return
    end
    
    filter_type = mapping[:predicate]
    @title = " - #{mapping[:label]}: #{term_label}"
    
    filter = "?item #{filter_type} ?term .
    FILTER (?term IN (<http://data.parliament.uk/terms/#{params[:id]}>))"
  end

  @items = get_items(filter, limit: 50, offset: 0)
  
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
      model: @model_class.name,
      total_count: @pagy.count,
      page: @pagy.page,
      per_page: @pagy.limit,
      items: @items.map { |item| item_to_json(item) }
    }
  end

  def item_to_json(item)
    {
      id: item.to_param,
      title: item.data['http://purl.org/dc/terms/title'],
      identifier: item.data['http://purl.org/dc/terms/identifier'],
      date: item.data['http://purl.org/dc/terms/date'] || item.data['http://data.parliament.uk/schema/parl#dateReceived'],
      url: item_path(item)
    }
  end 

end