# app/services/sparql_query_builder.rb
#
# Builds SPARQL queries from model templates with parameter substitution.
# Uses pre-generated query templates from model classes (see config/models.yml).
#
# Placeholders in query templates:
#   {{FILTER}}         - Term filter clause (e.g., ?item parl:topic <uri>)
#   {{OFFSET}}         - Pagination offset
#   {{LIMIT}}          - Pagination limit
#   {{SORT_BINDING}}   - Sort field binding (e.g., dc-term:date ?sortValue)
#   {{SORT_DIRECTION}} - Sort direction (ASC or DESC)
#
class SparqlQueryBuilder
  # Standard SPARQL prefixes used across all resource-type queries
  PREFIXES_HASH = {
    "parl" => "http://data.parliament.uk/schema/parl#",
    "dc-term" => "http://purl.org/dc/terms/",
    "skos" => "http://www.w3.org/2004/02/skos/core#",
    "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
    "xsd" => "http://www.w3.org/2001/XMLSchema#",
    "schema" => "http://schema.org/",
    "nfo" => "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#",
    "foaf" => "http://xmlns.com/foaf/0.1/",
    "ov" => "http://open.vocab.org/terms/"
  }.freeze

  # Builds a list query with pagination and sorting
  #
  # @param model_class [Class] Model class with query templates
  # @param filter [String] SPARQL filter clause for term filtering
  # @param offset [Integer] Pagination offset
  # @param limit [Integer] Number of items to return
  # @param all_fields [Boolean] Use LIST_QUERY_ALL (all fields) vs LIST_QUERY (index fields)
  # @param sort_field [Symbol] Field to sort by (defaults to model's DEFAULT_SORT_FIELD)
  # @param sort_order [Symbol] :asc or :desc (defaults to model's DEFAULT_SORT_ORDER)
  # @return [String] Complete SPARQL query
  #
  def self.list_query(model_class, filter, offset:, limit:, all_fields: false, sort_field: nil, sort_order: nil)
    query_template = all_fields ? model_class::LIST_QUERY_ALL : model_class::LIST_QUERY

    # Use defaults from model if not specified
    sort_field ||= model_class::DEFAULT_SORT_FIELD
    sort_order ||= model_class::DEFAULT_SORT_ORDER

    # Get the predicate URI for the sort field
    sort_binding = build_sort_binding(model_class, sort_field)
    sort_direction = sort_order.to_s.upcase == 'ASC' ? 'ASC' : 'DESC'

    query = query_template
      .gsub('{{FILTER}}', filter.to_s)
      .gsub('{{OFFSET}}', Integer(offset).to_s)
      .gsub('{{LIMIT}}', Integer(limit).to_s)
      .gsub('{{SORT_BINDING}}', sort_binding)
      .gsub('{{SORT_DIRECTION}}', sort_direction)

    Rails.logger.info { "[SPARQL] Generated list query for #{model_class.name}" }
    query
  end

  # Builds a show query for a single item
  #
  # @param model_class [Class] Model class with query templates
  # @param filter [String] SPARQL filter clause (typically FILTER(?item = <uri>))
  # @return [String] Complete SPARQL query
  #
  def self.show_query(model_class, filter)
    model_class::SHOW_QUERY.gsub('{{FILTER}}', filter.to_s)
  end

  # Returns the JSON-LD frame for a model
  #
  def self.frame(model_class)
    model_class::FRAME
  end

  private

  # Builds the SPARQL binding for sorting
  # Looks up the predicate URI from the model's ATTRIBUTES
  #
  # @example
  #   build_sort_binding(ResearchBriefing, :date) #=> "dc-term:date ?sortValue"
  #
  def self.build_sort_binding(model_class, sort_field)
    attr_config = model_class::ATTRIBUTES[sort_field.to_sym]

    predicate = if attr_config.is_a?(Hash)
                  attr_config[:uri]
                else
                  attr_config
                end

    "#{predicate} ?sortValue"
  end
end
