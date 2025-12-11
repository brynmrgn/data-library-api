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

  def self.frame(model_class = nil, context_type = 'show')
    puts "SparqlQueryBuilder.frame called with: #{model_class&.name}, context: #{context_type}"
    
    frame_context = PREFIXES_HASH.dup
    
    frame = {
      "@context" => frame_context,
      "@type" => model_class ? model_class::SPARQL_TYPE.gsub(/[<>]/, '') : nil,
      "@embed" => "@always"
    }.compact
    
    # If a model class is provided, dynamically add only its attributes
    if model_class
      # Use INDEX_ATTRIBUTES for list views, ATTRIBUTES for show views
      attributes = context_type == 'index' ? model_class::INDEX_ATTRIBUTES : model_class::ATTRIBUTES.keys
      
      puts "Using attributes for #{context_type}: #{attributes.inspect}"
      
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
      
      puts "Final frame predicates: #{frame.keys.reject { |k| k.start_with?('@') }.inspect}"
    end
    
    frame
  end

  def self.list_query(model_class, filter, offset:, limit:)
    construct_clause = build_construct_clause(model_class, :index)
    where_clause = build_where_clause(model_class, :index)
    sort_attr = model_class::SORT_BY || :dateReceived
    sort_attr_uri = model_class::ATTRIBUTES[sort_attr]
    
    required_where = build_required_where(model_class, :index)
    required_where_optional = build_required_where_optional(model_class, :index)
    
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

  def self.show_query(model_class, filter)
    construct_clause = build_construct_clause(model_class, :show)
    where_clause = build_where_clause(model_class, :show)
    required_where = build_required_where(model_class, :show)
    
    query = "#{PREFIXES}
    CONSTRUCT {
      ?item a #{model_class::SPARQL_TYPE} ;
      #{construct_clause}
    }
    WHERE {
      ?item #{required_where}
      #{where_clause}
      #{filter}
    }"
    
    query
  end
  
  private
  
  def self.get_attributes(model_class, context = :show)
    case context
    when :index
      index_keys = model_class::INDEX_ATTRIBUTES || model_class::ATTRIBUTES.keys
      model_class::ATTRIBUTES.slice(*index_keys)
    when :show
      model_class::ATTRIBUTES
    else
      model_class::ATTRIBUTES
    end
  end
  
  def self.build_required_where(model_class, context = :show)
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
  
  def self.build_construct_clause(model_class, context = :show)
    attributes = model_class::ATTRIBUTES
    index_attrs = context == :index ? model_class::INDEX_ATTRIBUTES : nil
    
    main_triples = []
    nested_triples = []
    
    attributes.each do |attr_name, attr_config|
      next if index_attrs && !index_attrs.include?(attr_name)
      
      puts "Processing: #{attr_name}, config: #{attr_config.inspect}"
      
      if attr_config.is_a?(Hash)
        uri = attr_config[:uri]
        main_triples << "#{uri} ?#{attr_name}"
        puts "  -> Nested object, adding main triple: #{uri} ?#{attr_name}"
        
        attr_config[:properties].each do |prop_name, prop_uri|
          nested_triples << "?#{attr_name} #{prop_uri} ?#{attr_name}_#{prop_name}"
          puts "  -> Adding nested triple: ?#{attr_name} #{prop_uri} ?#{attr_name}_#{prop_name}"
        end
      else
        main_triples << "#{attr_config} ?#{attr_name}"
        puts "  -> Simple property: #{attr_config} ?#{attr_name}"
      end
    end
    
    puts "Main triples: #{main_triples.inspect}"
    puts "Nested triples: #{nested_triples.inspect}"
    
    construct = main_triples.map { |t| "    #{t}" }.join(" ;\n")
    construct += " ."
    
    if nested_triples.any?
      construct += "\n  " + nested_triples.map { |t| "#{t} ." }.join("\n  ")
    end
    
    puts "Final construct:\n#{construct}\n\n"
    construct
  end
  
  def self.build_where_clause(model_class, context = :show)
    attributes = get_attributes(model_class, context)
    required = model_class::REQUIRED_ATTRIBUTES || []
    where_lines = []

    # Convert all keys to symbols for consistent access
    attributes = attributes.transform_keys(&:to_sym)
    required = required.map(&:to_sym)
    
    # Add optional attributes in OPTIONAL blocks ONLY
    attributes.each do |attr_name, attr_config|
      next if required.include?(attr_name)
      
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

  def self.build_required_where_optional(model_class, context = :show)
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