# lib/generators/model_generator.rb
#
# Code generator that reads config/models.yml and produces:
#   - A model class per resource type (app/models/<resource>.rb)
#   - A shared route config file (config/resource_config.rb) mapping URL paths
#     to model classes
#
# Supports two source types:
#   - SPARQL (default): generates LinkedDataResource subclass with SPARQL queries,
#     JSON-LD frame, and RDF predicate mappings
#   - REST (source: rest): generates RestApiResource subclass with upstream API
#     config and JSON field mappings
#
# Usage:
#   bin/rails generate:models
#
require 'yaml'
require 'fileutils'

class ModelGenerator
  # Standard SPARQL prefixes injected into every generated query
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

  # Pre-built PREFIX block for SPARQL queries
  PREFIXES = PREFIXES_HASH.map { |prefix, uri| "PREFIX #{prefix}: <#{uri}>" }.join("\n")

  # Reads config/models.yml and generates all model files and the resource config.
  # Overwrites existing generated files.
  #
  def self.generate_all
    config_path = Rails.root.join('config', 'models.yml')
    config = YAML.load_file(config_path)

    output_dir = Rails.root.join('app', 'models')
    FileUtils.mkdir_p(output_dir)

    resource_config = {}

    config.each do |key, model_config|
      # Convert hyphenated key to underscored for Ruby naming
      underscored_key = key.to_s.tr('-', '_')
      class_name = underscored_key.classify
      file_name = "#{underscored_key.singularize}.rb"
      source = model_config['source'] || 'sparql'

      puts "Generating #{class_name} (#{source})..."

      # Generate the model file based on source type
      model_code = if source == 'rest'
                     generate_rest_model(key, model_config)
                   else
                     generate_model(key, model_config)
                   end
      File.write(output_dir.join(file_name), model_code)

      # Build resource config entry (key is the route path)
      # Pluralize controller_name to avoid route name collisions
      # (e.g., "committee_business" singularizes to itself, causing index/show name clash)
      resource_config[key.to_s] = {
        controller_name: underscored_key.pluralize,
        model_class: class_name,
        source: source
      }
    end

    # Generate resource_config.rb (in config/ not models/)
    puts "Generating resource_config.rb..."
    resource_config_code = generate_resource_config(resource_config)
    File.write(Rails.root.join('config', 'resource_config.rb'), resource_config_code)

    puts "Done! Generated #{config.keys.count} models."
  end

  # Generates Ruby source code for a single model class
  #
  # @param key [String] The resource type key from models.yml (e.g., "research-briefings")
  # @param config [Hash] The YAML configuration for this resource type
  # @return [String] Ruby source code for the model file
  #
  def self.generate_model(key, config)
    underscored_key = key.to_s.tr('-', '_')
    class_name = underscored_key.classify

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
      # app/models/#{underscored_key.singularize}.rb
      # AUTO-GENERATED from config/models.yml - Do not edit!
      # Run: rake generate:models

      class #{class_name} < LinkedDataResource
        SPARQL_TYPE = '<#{config['sparql_type']}>'.freeze
        DEFAULT_SORT_FIELD = :#{config['sort_by']}
        DEFAULT_SORT_ORDER = :#{config['sort_order'] || 'desc'}
        SORTABLE_FIELDS = #{(config['sortable_fields'] || [config['sort_by']]).map(&:to_sym).inspect}.freeze
        REQUIRED_FILTER = #{config['required_filter'] ? format_hash(config['required_filter'].transform_keys(&:to_sym)) : 'nil'}

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

  # Generates Ruby source code for a REST API model class
  #
  # @param key [String] The resource type key from models.yml (e.g., "committees")
  # @param config [Hash] The YAML configuration for this resource type
  # @return [String] Ruby source code for the model file
  #
  def self.generate_rest_model(key, config)
    underscored_key = key.to_s.tr('-', '_')
    class_name = underscored_key.classify

    attributes = parse_rest_attributes(config['attributes'])
    index_attrs = config['index_attributes'].map(&:to_sym)
    required_attrs = config['required_attributes'].map(&:to_sym)
    filter_mappings = parse_filter_mappings(config['filter_mappings'])
    response_format_line = config['response_format'] == 'array' ? "\n    API_RESPONSE_FORMAT = \"array\".freeze\n" : ''

    <<~RUBY
      # app/models/#{underscored_key.singularize}.rb
      # AUTO-GENERATED from config/models.yml - Do not edit!
      # Run: rake generate:models

      class #{class_name} < RestApiResource
        BASE_URL = #{config['base_url'].inspect}.freeze
        API_PATH = #{config['api_path'].inspect}.freeze
        ID_FIELD = #{(config['id_field'] || 'id').inspect}.freeze

        DEFAULT_SORT_FIELD = :#{config['sort_by']}
        DEFAULT_SORT_ORDER = :#{config['sort_order'] || 'asc'}
        SORTABLE_FIELDS = #{(config['sortable_fields'] || [config['sort_by']]).map(&:to_sym).inspect}.freeze

        ATTRIBUTES = #{format_hash(attributes)}.freeze

        INDEX_ATTRIBUTES = #{index_attrs.inspect}.freeze
        REQUIRED_ATTRIBUTES = #{required_attrs.inspect}.freeze

        TERM_TYPE_MAPPINGS = {}.freeze

        FILTER_MAPPINGS = #{format_hash(filter_mappings)}.freeze
    #{response_format_line}
        def self.construct_uri(id)
          "\#{BASE_URL}\#{API_PATH}/\#{id}"
        end

        finalize_attributes!
      end
    RUBY
  end

  # Generates the RESOURCE_CONFIG constant mapping URL paths to model classes
  #
  # @param config [Hash] Map of route paths to controller/model info
  # @return [String] Ruby source code for config/resource_config.rb
  #
  def self.generate_resource_config(config)
    <<~RUBY
      # config/resource_config.rb
      # AUTO-GENERATED from config/models.yml - Do not edit!
      # Run: rake generate:models

      RESOURCE_CONFIG = #{format_hash(config)}.freeze
    RUBY
  end

  private

  # Converts YAML attribute config for REST resources into a Ruby hash.
  # Simple attributes become { name: "json_field" }.
  # Nested attributes become { name: { json_key: "field", properties: { ... } } }.
  #
  # @param attrs_config [Hash] Raw attributes from YAML
  # @return [Hash] Parsed attributes with symbol keys
  #
  def self.parse_rest_attributes(attrs_config)
    result = {}
    attrs_config.each do |name, value|
      if value.is_a?(Hash)
        result[name.to_sym] = {
          json_key: value['json_key'],
          properties: value['properties'].transform_keys(&:to_sym)
        }
      else
        result[name.to_sym] = value
      end
    end
    result
  end

  # Converts YAML filter mappings for REST resources into a Ruby hash.
  #
  # @param mappings_config [Hash, nil] Raw filter mappings from YAML
  # @return [Hash] Parsed mappings with upstream_param, label, default, values
  #
  def self.parse_filter_mappings(mappings_config)
    return {} unless mappings_config

    result = {}
    mappings_config.each do |name, value|
      entry = { upstream_param: value['upstream_param'], label: value['label'] }
      entry[:default] = value['default'] if value['default']
      entry[:values] = value['values'] if value['values']
      result[name.to_sym] = entry
    end
    result
  end

  # Converts YAML attribute config for SPARQL resources into a Ruby hash.
  # Simple attributes become { name: "predicate" }.
  # Nested attributes become { name: { uri: "predicate", properties: { ... } } }.
  #
  # @param attrs_config [Hash] Raw attributes from YAML
  # @return [Hash] Parsed attributes with symbol keys
  #
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

  # Converts YAML term type mappings into a Ruby hash for filtering support
  #
  # @param mappings_config [Hash, nil] Raw term mappings from YAML
  # @return [Hash] Parsed mappings with predicate, label, and optional nested config
  #
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

  # Generates a SPARQL CONSTRUCT query for listing items with pagination and sorting.
  # Uses a subquery pattern: the inner SELECT handles filtering, sorting, and pagination,
  # while the outer CONSTRUCT fetches the requested attributes for matched items.
  #
  # @param config [Hash] Model YAML config (for sparql_type, required_filter, etc.)
  # @param attrs_to_include [Array<Symbol>] Attributes to include in the CONSTRUCT
  # @param all_attributes [Hash] Full attribute definitions for predicate lookups
  # @return [String] SPARQL query with {{FILTER}}, {{OFFSET}}, {{LIMIT}} placeholders
  #
  def self.generate_list_query(config, attrs_to_include, all_attributes)
    sparql_type = "<#{config['sparql_type']}>"
    required_attrs = config['required_attributes'].map(&:to_sym)
    required_filter_clause = build_required_filter_clause(config['required_filter'])

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
              {{SORT_BINDING}} .
            #{required_filter_clause}{{FILTER}}
          }
          ORDER BY {{SORT_DIRECTION}}(?sortValue)
          OFFSET {{OFFSET}}
          LIMIT {{LIMIT}}
        }
      }
    SPARQL
  end

  # Generates a SPARQL CONSTRUCT query for fetching a single item.
  # Includes all attributes (no pagination or sorting needed).
  #
  # @param config [Hash] Model YAML config
  # @param attributes [Hash] Full attribute definitions
  # @return [String] SPARQL query with {{FILTER}} placeholder
  #
  def self.generate_show_query(config, attributes)
    sparql_type = "<#{config['sparql_type']}>"
    required_attrs = config['required_attributes'].map(&:to_sym)
    required_filter_clause = build_required_filter_clause(config['required_filter'])

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
        #{required_filter_clause}{{FILTER}}
      }
    SPARQL
  end

  # Generates a JSON-LD frame for shaping SPARQL CONSTRUCT responses.
  # The frame is built dynamically from the model's attributes.
  # A single frame works for both list and show queries - missing
  # attributes are simply omitted from the framed output.
  #
  # @param config [Hash] Model YAML config (for sparql_type)
  # @param attributes [Hash] Attribute definitions
  # @return [Hash] JSON-LD frame
  #
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

  # Builds the CONSTRUCT clause triples for the given attributes.
  # Simple attributes produce a single triple; nested attributes produce
  # additional triples for sub-properties.
  #
  # @param attrs_to_include [Array<Symbol>] Attributes to include
  # @param all_attributes [Hash] Full attribute definitions
  # @return [String] SPARQL CONSTRUCT clause body
  #
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

  # Builds OPTIONAL WHERE clause patterns for non-required attributes.
  # Required attributes are handled separately (in the subquery) so they
  # are not wrapped in OPTIONAL here.
  #
  # @param attrs_to_include [Array<Symbol>] Attributes to include
  # @param all_attributes [Hash] Full attribute definitions
  # @param required_attrs [Array<Symbol>] Required attributes (excluded from OPTIONAL)
  # @return [String] SPARQL WHERE clause with OPTIONAL blocks
  #
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

  # Builds non-optional WHERE triples for required attributes (used in subquery)
  #
  # @param required_attrs [Array<Symbol>] Required attribute names
  # @param all_attributes [Hash] Full attribute definitions
  # @return [String] Semicolon-joined triple patterns
  #
  def self.build_required_where(required_attrs, all_attributes)
    lines = required_attrs.map do |attr_name|
      uri = get_uri(all_attributes[attr_name])
      "#{uri} ?#{attr_name}"
    end
    lines.join(" ;\n          ") + " ."
  end

  # Builds OPTIONAL patterns for required attributes in the outer WHERE clause.
  # These are OPTIONAL in the outer query because the inner subquery already
  # ensures the item has these attributes.
  #
  # @param required_attrs [Array<Symbol>] Required attribute names
  # @param all_attributes [Hash] Full attribute definitions
  # @return [String] OPTIONAL blocks for required attributes
  #
  def self.build_required_where_optional(required_attrs, all_attributes)
    required_attrs.map do |attr_name|
      uri = get_uri(all_attributes[attr_name])
      "OPTIONAL { ?item #{uri} ?#{attr_name} . }"
    end.join("\n    ")
  end

  # Extracts the RDF predicate URI from an attribute config
  #
  # @param attr_config [String, Hash, nil] Simple predicate string or nested config hash
  # @return [String, nil] The predicate URI
  #
  def self.get_uri(attr_config)
    return nil unless attr_config
    attr_config.is_a?(Hash) ? attr_config[:uri] : attr_config
  end

  # Builds a SPARQL filter clause for required_filter config
  # Returns empty string if no required_filter defined
  # Generates case-insensitive string matching
  #
  def self.build_required_filter_clause(filter_config)
    return '' unless filter_config

    predicate = filter_config['predicate']
    value = filter_config['value'].to_s.downcase

    <<~SPARQL
      ?item #{predicate} ?_rf_value .
            FILTER(LCASE(STR(?_rf_value)) = "#{value}")
    SPARQL
  end

  # Formats a Ruby hash as pretty-printed source code for embedding in generated files
  #
  # @param hash [Hash] The hash to format
  # @param indent_level [Integer] Current indentation depth
  # @return [String] Ruby hash literal as source code
  #
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

  # Formats a single value as Ruby source code
  #
  # @param value [Object] The value to format
  # @param indent_level [Integer] Current indentation depth (for nested hashes)
  # @return [String] Ruby literal as source code
  #
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

  # Indents each line of text by the given number of spaces
  #
  # @param text [String] Multi-line text to indent
  # @param spaces [Integer] Number of spaces to prepend to each line
  # @return [String] Indented text
  #
  def self.indent(text, spaces)
    text.lines.map { |line| (' ' * spaces) + line }.join
  end
end
