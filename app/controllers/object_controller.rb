# app/controllers/content_controller.rb
class ObjectController < ApplicationController
  include Sparql::Get::Response
  
  def index
    model_name = params[:controller_name].classify
    @model_class = model_name.constantize
    
    # Get the module instances
    items_module = "Sparql::Get::#{model_name.pluralize}".constantize
    queries_module = "Sparql::Queries::#{model_name.pluralize}".constantize
    
    # Extend self with the modules to get their methods
    self.class.include(items_module)
    self.class.include(queries_module)
    
    filter = ""
    @title = ""

  if params['term_type']
    term_label = helpers.get_term_label(params[:id])
    
    # Get the term type mappings from the model
    mappings = @model_class::TERM_TYPE_MAPPINGS
    mapping = mappings[params['term_type'].to_s]
    
    if mapping.nil?
      Rails.logger.error "Invalid term_type '#{params['term_type']}' for #{@model_class}"
      render plain: "Invalid filter type '#{params['term_type']}' for #{params[:controller_name]}", status: :not_found
      return
    end
    
    filter_type = mapping[:predicate]
    @title = ": #{mapping[:label]}: #{term_label}"
    
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
    
    render partial: 'shared/index'
  end

def show
  model_name = params[:controller_name].classify
  @model_class = model_name.constantize
  
  # Include BOTH the Get and Queries modules
  item_module = "Sparql::Get::#{model_name.singularize}".constantize
  queries_module = "Sparql::Queries::#{model_name.pluralize}".constantize
  
  self.class.include(item_module)
  self.class.include(queries_module)
  
  @item = get_item(params[:id])
  
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

end