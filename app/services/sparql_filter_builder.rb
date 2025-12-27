# app/services/sparql_filter_builder.rb
#
# Builds SPARQL FILTER clauses from request parameters.
# Allows filtering resources by taxonomy terms (topic, subject, publisher, etc.)
#
# @example Filter by topic
#   GET /research-briefings?topic=12345
#   # Generates: ?item parl:topic ?12345_term . FILTER(?12345_term IN (<http://...>))
#
# @example Filter by multiple terms
#   GET /research-briefings?topic=123&publisher=456
#   # Generates both filter clauses, combined with AND
#
# Uses model's TERM_TYPE_MAPPINGS to know which predicate to use for each filter type.
#
class SparqlFilterBuilder
  def initialize(model_class, params)
    @model_class = model_class
    @params = params
  end

  # Builds SPARQL filter clause string from request parameters
  #
  def build
    mappings = @model_class::TERM_TYPE_MAPPINGS
    active_filters = find_active_filters(mappings)

    return "" if active_filters.empty?

    filter_clauses = active_filters.map do |term_type, term_id|
      build_filter_clause(mappings[term_type], term_id)
    end

    filter_clauses.join("\n")
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
