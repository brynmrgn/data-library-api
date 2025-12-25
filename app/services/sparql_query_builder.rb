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

  def self.list_query(model_class, filter, offset:, limit:, all_fields: false)
    query_template = all_fields ? model_class::LIST_QUERY_ALL : model_class::LIST_QUERY

    query_template
      .gsub('{{FILTER}}', filter.to_s)
      .gsub('{{OFFSET}}', Integer(offset).to_s)
      .gsub('{{LIMIT}}', Integer(limit).to_s)
  end

  def self.show_query(model_class, filter)
    model_class::SHOW_QUERY.gsub('{{FILTER}}', filter.to_s)
  end

  def self.frame(model_class)
    model_class::FRAME
  end
end
