# app/services/sparql_query_builder.rb
# Simplified query builder - uses pre-generated queries from model classes
# with simple template substitution

class SparqlQueryBuilder
  PREFIXES_HASH = {
    "parl" => "http://data.parliament.uk/schema/parl#",
    "dc-term" => "http://purl.org/dc/terms/",
    "skos" => "http://www.w3.org/2004/02/skos/core#",
    "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
    "xsd" => "http://www.w3.org/2001/XMLSchema#",
    "schema" => "http://schema.org/",
    "nfo" => "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#",
    "foaf" => "http://xmlns.com/foaf/0.1/"
  }.freeze

  def self.list_query(model_class, filter, offset:, limit:, all_fields: false, sort_field: nil, sort_order: nil)
    query_template = all_fields ? model_class::LIST_QUERY_ALL : model_class::LIST_QUERY

    # Use defaults from model if not specified
    sort_field ||= model_class::DEFAULT_SORT_FIELD
    sort_order ||= model_class::DEFAULT_SORT_ORDER

    # Get the predicate URI for the sort field
    sort_binding = build_sort_binding(model_class, sort_field)
    sort_direction = sort_order.to_s.upcase == 'ASC' ? 'ASC' : 'DESC'

    query_template
      .gsub('{{FILTER}}', filter.to_s)
      .gsub('{{OFFSET}}', Integer(offset).to_s)
      .gsub('{{LIMIT}}', Integer(limit).to_s)
      .gsub('{{SORT_BINDING}}', sort_binding)
      .gsub('{{SORT_DIRECTION}}', sort_direction)
  end

  # Builds the SPARQL binding for the sort field
  # e.g., "dc-term:date ?sortValue"
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

  def self.show_query(model_class, filter)
    model_class::SHOW_QUERY.gsub('{{FILTER}}', filter.to_s)
  end

  def self.frame(model_class)
    model_class::FRAME
  end
end
