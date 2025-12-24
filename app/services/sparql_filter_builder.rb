# app/services/sparql_filter_builder.rb
#
# Service responsible for building SPARQL filter clauses based on request parameters
# Handles both query parameter and route-based filtering
#
class SparqlFilterBuilder
  attr_reader :filter, :title, :term_id
  
  def initialize(model_class, params, helpers)
    @model_class = model_class
    @params = params
    @helpers = helpers
    @filter = ""
    @title = ""
    @term_id = nil
  end
  
  # Builds filter clause based on request parameters
  # Returns self for method chaining
  #
  def build
    mappings = @model_class::TERM_TYPE_MAPPINGS
    term_type = find_term_type(mappings)
    
    return self if term_type.nil?
    
    mapping = mappings[term_type.to_s]
    
    raise ArgumentError, "Invalid term_type '#{term_type}'" if mapping.nil?
    
    term_label = @helpers.get_term_label(@term_id)
    filter_type = mapping[:predicate]
    @title = ": #{mapping[:label]}: #{term_label}"
    
    @filter = build_filter_clause(filter_type, mapping)
    
    self
  end
  
  private
  
  # Finds term_type from query params or route params
  #
  def find_term_type(mappings)
    # Check query parameters first
    mappings.keys.each do |key|
      if @params[key].present?
        @term_id = @params[key]
        return key
      end
    end
    
    # Fallback to route-based filtering
    if @params['term_type'].present?
      @term_id = @params[:id]
      return @params['term_type']
    end
    
    nil
  end
  
  # Builds SPARQL filter clause for the given mapping
  #
  def build_filter_clause(filter_type, mapping)
    if mapping[:nested]
      "?item #{filter_type} ?authorResource . 
       ?authorResource #{mapping[:nested_predicate]} ?term . 
       FILTER (?term IN (<http://data.parliament.uk/terms/#{@term_id}>))"
    else
      "?item #{filter_type} ?term . 
       FILTER (?term IN (<http://data.parliament.uk/terms/#{@term_id}>))"
    end
  end
end