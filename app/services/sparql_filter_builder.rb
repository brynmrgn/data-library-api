# app/services/sparql_filter_builder.rb
#
# Service responsible for building SPARQL filter clauses based on request parameters
# Supports multiple filter parameters (e.g., ?topic=123&publisher=456)
#
class SparqlFilterBuilder
  attr_reader :filter, :title

  def initialize(model_class, params, helpers)
    @model_class = model_class
    @params = params
    @helpers = helpers
    @filter = ""
    @title = ""
  end

  # Builds filter clause based on request parameters
  # Returns self for method chaining
  #
  def build
    mappings = @model_class::TERM_TYPE_MAPPINGS
    active_filters = find_active_filters(mappings)

    return self if active_filters.empty?

    filter_clauses = []
    title_parts = []

    active_filters.each do |term_type, term_id|
      mapping = mappings[term_type]
      term_label = @helpers.get_term_label(term_id)

      title_parts << "#{mapping[:label]}: #{term_label}"
      filter_clauses << build_filter_clause(mapping, term_id)
    end

    @title = ": #{title_parts.join(', ')}"
    @filter = filter_clauses.join("\n")

    self
  end

  private

  # Finds all active filters from query params
  # Returns hash of { term_type => term_id }
  #
  def find_active_filters(mappings)
    filters = {}

    mappings.keys.each do |key|
      if @params[key].present?
        filters[key] = @params[key]
      end
    end

    filters
  end

  # Builds SPARQL filter clause for the given mapping
  #
  def build_filter_clause(mapping, term_id)
    filter_type = mapping[:predicate]

    if mapping[:nested]
      "?item #{filter_type} ?#{term_id}_resource .
       ?#{term_id}_resource #{mapping[:nested_predicate]} ?#{term_id}_term .
       FILTER (?#{term_id}_term IN (<http://data.parliament.uk/terms/#{term_id}>))"
    else
      "?item #{filter_type} ?#{term_id}_term .
       FILTER (?#{term_id}_term IN (<http://data.parliament.uk/terms/#{term_id}>))"
    end
  end
end
