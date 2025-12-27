# app/models/linked_data_resource.rb
#
# Base class for all linked data resources (research briefings, deposited papers, etc.)
# Subclasses are auto-generated from config/models.yml by the model generator.
#
# Each subclass defines:
#   - SPARQL_TYPE: The RDF type URI for this resource
#   - ATTRIBUTES: Hash mapping attribute names to RDF predicates
#   - INDEX_ATTRIBUTES: Fields to include in list views
#   - REQUIRED_ATTRIBUTES: Fields that must be present
#   - TERM_TYPE_MAPPINGS: How to filter by taxonomy terms
#   - LIST_QUERY, LIST_QUERY_ALL, SHOW_QUERY: SPARQL query templates
#   - FRAME: JSON-LD frame for response shaping
#
# @example
#   briefing = ResearchBriefing.new(id: "123", data: json_ld_hash)
#   briefing.title  # => "Brexit: an overview"
#   briefing.uri    # => "http://data.parliament.uk/resources/123"
#
class LinkedDataResource
  attr_reader :id, :data, :resource_type

  def initialize(id:, data:, resource_type: nil)
    @id = id
    @data = data
    @resource_type = resource_type
  end

  # Returns the full URI from the JSON-LD @id
  def uri
    data['@id']
  end

  # Hook called when a subclass is defined
  # Sets up the finalize_attributes! method that creates accessor methods
  #
  def self.inherited(subclass)
    super

    subclass.define_singleton_method(:finalize_attributes!) do
      return unless const_defined?(:ATTRIBUTES)

      self::ATTRIBUTES.each do |attr_name, config|
        next if method_defined?(attr_name)

        predicate = config.is_a?(Hash) ? config[:uri] : config

        define_method(attr_name) do
          data[predicate]
        end
      end
    end
  end
end