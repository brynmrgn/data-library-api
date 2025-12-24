# app/services/sparql_query_builder.rb
require 'uri'
require 'net/http'
require 'json'
require 'json/ld'

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

  PREFIXES = PREFIXES_HASH.map { |prefix, uri| "PREFIX #{prefix}: <#{uri}>" }.join("\n")

  def self.frame(model_class = nil, attributes = nil)
    frame_context = PREFIXES_HASH.dup
    
    frame = {
      "@context" => frame_context,
      "@type" => model_class ? model_class::SPARQL_TYPE.gsub(/[<>]/, '') : nil,
      "@embed" => "@always"
    }.compact
    
    # If a model class is provided, dynamically add only its attributes
    if model_class && attributes
      # Convert attribute symbols to their predicates
      attributes.each do |attr|
        attribute_config = model_class::ATTRIBUTES[attr]
        
        # Handle both simple strings and nested hashes
        predicate = if attribute_config.is_a?(Hash)
          attribute_config[:uri]
        else
          attribute_config
        end
        
        if predicate
          frame[predicate] = { "@embed" => "@always" }
        else
          puts "WARNING: No predicate found for attribute #{attr}"
        end
      end
    end
    
    frame
  end

  def self.list_query(model_class, filter, offset:, limit:, attributes:)
    construct_clause = build_construct_clause(model_class, attributes)
    where_clause = build_where_clause(model_class, attributes)
    sort_attr = model_class::SORT_BY || :dateReceived
    sort_attr_uri = model_class::ATTRIBUTES[sort_attr]
    
    required_where = build_required_where(model_class)
    required_where_optional = build_required_where_optional(model_class)
    
    query = "#{PREFIXES}
    CONSTRUCT {
      ?item a #{model_class::SPARQL_TYPE} ;
      #{construct_clause}
    }
    WHERE {
      #{required_where_optional}
      #{where_clause}
      
      {
        SELECT ?item ?sortValue
        WHERE {
          ?item a #{model_class::SPARQL_TYPE} ;
            #{required_where.gsub(/\.$/, '')} ;
            #{sort_attr_uri} ?sortValue .
          #{filter}
        }
        ORDER BY DESC(?sortValue)
        OFFSET #{Integer(offset)}
        LIMIT #{Integer(limit)}
      }
    }"
    
    query
  end

  def self.show_query(model_class, filter, attributes: nil)
    # Structure show queries similarly to list queries:
    # same CONSTRUCT/WHERE shape, but without pagination/sorting
    attributes ||= model_class::ATTRIBUTES.keys

    construct_clause         = build_construct_clause(model_class, attributes)
    where_clause             = build_where_clause(model_class, attributes)
    required_where_optional  = build_required_where_optional(model_class)

    "#{PREFIXES}
    CONSTRUCT {
      ?item a #{model_class::SPARQL_TYPE} ;
      #{construct_clause}
    }
    WHERE {
      ?item a #{model_class::SPARQL_TYPE} .
      #{required_where_optional}
      #{where_clause}
      #{filter}
    }"
  end
  
  private
  
  # Removed get_attributes method - no longer needed!
  
  def self.build_required_where(model_class)
    attributes = model_class::ATTRIBUTES
    required = model_class::REQUIRED_ATTRIBUTES || []
    lines = required.map do |attr_name|
      uri = attributes[attr_name]
      if uri.is_a?(Hash)
        uri = uri[:uri]
      end
      "#{uri} ?#{attr_name}"
    end
    lines.join(" ;\n        ") + " ."
  end
  
def self.build_construct_clause(model_class, attributes_to_include)
  all_attributes = model_class::ATTRIBUTES
  
  main_triples = []
  nested_blocks = []
  
  attributes_to_include.each do |attr_name|
    attr_config = all_attributes[attr_name]
    next unless attr_config
    
    if attr_config.is_a?(Hash)
      uri = attr_config[:uri]
      main_triples << "#{uri} ?#{attr_name}"
      
      # Build nested block with type declaration
      nested_lines = ["?#{attr_name} a #{uri} ;"]
      
      props = attr_config[:properties].map do |prop_name, prop_uri|
        "  #{prop_uri} ?#{attr_name}_#{prop_name}"
      end
      
      nested_lines << props.join(" ;\n")
      nested_lines << " ."
      nested_blocks << nested_lines.join("\n")
    else
      main_triples << "#{attr_config} ?#{attr_name}"
    end
  end
  
  construct = main_triples.map { |t| "    #{t}" }.join(" ;\n")
  construct += " ."
  
  if nested_blocks.any?
    construct += "\n  " + nested_blocks.join("\n  ")
  end
  
  construct
end
  
  def self.build_where_clause(model_class, attributes_to_include)
    all_attributes = model_class::ATTRIBUTES
    required = model_class::REQUIRED_ATTRIBUTES || []
    where_lines = []
    
    # Only process the attributes we were asked to include
    attributes_to_include.each do |attr_name|
      next if required.include?(attr_name)  # Skip required attributes
      
      attr_config = all_attributes[attr_name]
      next unless attr_config  # Skip if attribute doesn't exist
      
      if attr_config.is_a?(Hash)
        uri = attr_config[:uri]
        optional_block = "OPTIONAL { ?item #{uri} ?#{attr_name} ."
        
        attr_config[:properties].each do |prop_name, prop_uri|
          optional_block += "\n    ?#{attr_name} #{prop_uri} ?#{attr_name}_#{prop_name} ."
        end
        
        optional_block += "\n  }"
        where_lines << optional_block
      else
        where_lines << "OPTIONAL { ?item #{attr_config} ?#{attr_name} . }"
      end
    end
    
    where_lines.join("\n")
  end

  def self.build_required_where_optional(model_class)
    attributes = model_class::ATTRIBUTES
    required = model_class::REQUIRED_ATTRIBUTES || []
    
    required.map do |attr_name|
      uri = attributes[attr_name]
      if uri.is_a?(Hash)
        uri = uri[:uri]
      end
      "OPTIONAL { ?item #{uri} ?#{attr_name} . }"
    end.join("\n      ")
  end
end