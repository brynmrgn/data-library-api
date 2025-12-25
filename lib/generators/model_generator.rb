# lib/generators/model_generator.rb
# Generates model files, SPARQL queries, and frames from config/models.yml

require 'yaml'
require 'fileutils'

class ModelGenerator
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

  def self.generate_all
    config_path = Rails.root.join('config', 'models.yml')
    config = YAML.load_file(config_path)

    output_dir = Rails.root.join('app', 'models')
    FileUtils.mkdir_p(output_dir)

    resource_config = {}

    config.each do |key, model_config|
      class_name = key.to_s.classify
      file_name = "#{key.to_s.singularize}.rb"

      puts "Generating #{class_name}..."

      # Generate the model file
      model_code = generate_model(key, model_config)
      File.write(output_dir.join(file_name), model_code)

      # Build resource config entry
      resource_config[key.to_sym] = {
        route_path: model_config['route_path'],
        controller_name: key.to_s,
        model_class: class_name
      }
    end

    # Generate resource_config.rb
    puts "Generating resource_config.rb..."
    resource_config_code = generate_resource_config(resource_config)
    File.write(output_dir.join('resource_config.rb'), resource_config_code)

    puts "Done! Generated #{config.keys.count} models."
  end

  def self.generate_model(key, config)
    class_name = key.to_s.classify

    # Parse attributes from config
    attributes = parse_attributes(config['attributes'])
    index_attrs = config['index_attributes'].map(&:to_sym)
    required_attrs = config['required_attributes'].map(&:to_sym)
    term_mappings = parse_term_mappings(config['term_type_mappings'])

    # Generate queries
    list_query = generate_list_query(config, index_attrs, attributes)
    list_query_all = generate_list_query(config, attributes.keys, attributes)
    show_query = generate_show_query(config, attributes)
    frame = generate_frame(config, attributes)

    <<~RUBY
      # app/models/#{key.to_s.singularize}.rb
      # AUTO-GENERATED from config/models.yml - Do not edit!
      # Run: rake generate:models

      class #{class_name} < LinkedDataResource
        include SparqlQueryable
        include PresentationHelpers

        SPARQL_TYPE = '<#{config['sparql_type']}>'.freeze
        SORT_BY = :#{config['sort_by']}

        ATTRIBUTES = #{format_hash(attributes)}.freeze

        INDEX_ATTRIBUTES = #{index_attrs.inspect}.freeze
        REQUIRED_ATTRIBUTES = #{required_attrs.inspect}.freeze

        TERM_TYPE_MAPPINGS = #{format_hash(term_mappings)}.freeze

        LIST_QUERY = <<~SPARQL
      #{indent(list_query, 4)}
        SPARQL

        LIST_QUERY_ALL = <<~SPARQL
      #{indent(list_query_all, 4)}
        SPARQL

        SHOW_QUERY = <<~SPARQL
      #{indent(show_query, 4)}
        SPARQL

        FRAME = #{format_hash(frame)}.freeze

        def self.construct_uri(id)
          "#{config['base_uri'].gsub('{id}', '#{id}')}"
        end

        finalize_attributes!
      end
    RUBY
  end

  def self.generate_resource_config(config)
    <<~RUBY
      # app/models/resource_config.rb
      # AUTO-GENERATED from config/models.yml - Do not edit!
      # Run: rake generate:models

      RESOURCE_CONFIG = #{format_hash(config)}.freeze
    RUBY
  end

  private

  def self.parse_attributes(attrs_config)
    result = {}
    attrs_config.each do |name, value|
      if value.is_a?(Hash)
        result[name.to_sym] = {
          uri: value['uri'],
          properties: value['properties'].transform_keys(&:to_sym)
        }
      else
        result[name.to_sym] = value
      end
    end
    result
  end

  def self.parse_term_mappings(mappings_config)
    return {} unless mappings_config

    result = {}
    mappings_config.each do |name, value|
      if value.is_a?(Hash)
        entry = { predicate: value['predicate'], label: value['label'] }
        entry[:nested] = true if value['nested']
        entry[:nested_predicate] = value['nested_predicate'] if value['nested_predicate']
        result[name.to_s] = entry
      else
        result[name.to_s] = { predicate: value, label: name }
      end
    end
    result
  end

  def self.generate_list_query(config, attrs_to_include, all_attributes)
    sparql_type = "<#{config['sparql_type']}>"
    sort_attr = config['sort_by'].to_sym
    sort_uri = get_uri(all_attributes[sort_attr])
    required_attrs = config['required_attributes'].map(&:to_sym)

    construct_clause = build_construct_clause(attrs_to_include, all_attributes)
    where_clause = build_where_clause(attrs_to_include, all_attributes, required_attrs)
    required_where = build_required_where(required_attrs, all_attributes)
    required_where_optional = build_required_where_optional(required_attrs, all_attributes)

    <<~SPARQL.strip
      #{PREFIXES}
      CONSTRUCT {
        ?item a #{sparql_type} ;
      #{construct_clause}
      }
      WHERE {
        #{required_where_optional}
      #{where_clause}

        {
          SELECT ?item ?sortValue
          WHERE {
            ?item a #{sparql_type} ;
              #{required_where.gsub(/\.$/, '')} ;
              #{sort_uri} ?sortValue .
            {{FILTER}}
          }
          ORDER BY DESC(?sortValue)
          OFFSET {{OFFSET}}
          LIMIT {{LIMIT}}
        }
      }
    SPARQL
  end

  def self.generate_show_query(config, attributes)
    sparql_type = "<#{config['sparql_type']}>"
    required_attrs = config['required_attributes'].map(&:to_sym)

    construct_clause = build_construct_clause(attributes.keys, attributes)
    where_clause = build_where_clause(attributes.keys, attributes, required_attrs)
    required_where_optional = build_required_where_optional(required_attrs, attributes)

    <<~SPARQL.strip
      #{PREFIXES}
      CONSTRUCT {
        ?item a #{sparql_type} ;
      #{construct_clause}
      }
      WHERE {
        ?item a #{sparql_type} .
        #{required_where_optional}
      #{where_clause}
        {{FILTER}}
      }
    SPARQL
  end

  def self.generate_frame(config, attributes)
    frame = {
      "@context" => PREFIXES_HASH.dup,
      "@type" => config['sparql_type'],
      "@embed" => "@always"
    }

    attributes.each do |attr_name, attr_config|
      uri = get_uri(attr_config)
      frame[uri] = { "@embed" => "@always" } if uri
    end

    frame
  end

  def self.build_construct_clause(attrs_to_include, all_attributes)
    main_triples = []
    nested_blocks = []

    attrs_to_include.each do |attr_name|
      attr_config = all_attributes[attr_name]
      next unless attr_config

      if attr_config.is_a?(Hash)
        uri = attr_config[:uri]
        main_triples << "#{uri} ?#{attr_name}"

        nested_lines = ["?#{attr_name} a #{uri} ;"]
        props = attr_config[:properties].map do |prop_name, prop_uri|
          "    #{prop_uri} ?#{attr_name}_#{prop_name}"
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

  def self.build_where_clause(attrs_to_include, all_attributes, required_attrs)
    where_lines = []

    attrs_to_include.each do |attr_name|
      next if required_attrs.include?(attr_name)

      attr_config = all_attributes[attr_name]
      next unless attr_config

      if attr_config.is_a?(Hash)
        uri = attr_config[:uri]
        optional_block = "  OPTIONAL { ?item #{uri} ?#{attr_name} ."

        attr_config[:properties].each do |prop_name, prop_uri|
          optional_block += "\n      ?#{attr_name} #{prop_uri} ?#{attr_name}_#{prop_name} ."
        end

        optional_block += "\n    }"
        where_lines << optional_block
      else
        where_lines << "  OPTIONAL { ?item #{attr_config} ?#{attr_name} . }"
      end
    end

    where_lines.join("\n")
  end

  def self.build_required_where(required_attrs, all_attributes)
    lines = required_attrs.map do |attr_name|
      uri = get_uri(all_attributes[attr_name])
      "#{uri} ?#{attr_name}"
    end
    lines.join(" ;\n          ") + " ."
  end

  def self.build_required_where_optional(required_attrs, all_attributes)
    required_attrs.map do |attr_name|
      uri = get_uri(all_attributes[attr_name])
      "OPTIONAL { ?item #{uri} ?#{attr_name} . }"
    end.join("\n    ")
  end

  def self.get_uri(attr_config)
    return nil unless attr_config
    attr_config.is_a?(Hash) ? attr_config[:uri] : attr_config
  end

  def self.format_hash(hash, indent_level = 0)
    return '{}' if hash.nil? || hash.empty?

    indent = '  ' * indent_level
    inner_indent = '  ' * (indent_level + 1)

    lines = hash.map do |key, value|
      formatted_key = key.is_a?(Symbol) ? key.inspect : key.inspect
      formatted_value = format_value(value, indent_level + 1)
      "#{inner_indent}#{formatted_key} => #{formatted_value}"
    end

    "{\n#{lines.join(",\n")}\n#{indent}}"
  end

  def self.format_value(value, indent_level)
    case value
    when Hash
      format_hash(value, indent_level)
    when Symbol
      value.inspect
    when String
      value.inspect
    when Array
      value.inspect
    when TrueClass, FalseClass, NilClass, Numeric
      value.inspect
    else
      value.inspect
    end
  end

  def self.indent(text, spaces)
    text.lines.map { |line| (' ' * spaces) + line }.join
  end
end
