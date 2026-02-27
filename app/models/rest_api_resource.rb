# app/models/rest_api_resource.rb
#
# Base class for all REST API-sourced resources (committees, etc.)
# Parallels LinkedDataResource but works with plain JSON instead of JSON-LD.
#
# Each subclass defines:
#   - BASE_URL: The upstream API base URL
#   - API_PATH: The API endpoint path
#   - ID_FIELD: The JSON field name for the item ID
#   - ATTRIBUTES: Hash mapping attribute names to JSON field names
#   - INDEX_ATTRIBUTES: Fields to include in list views
#   - REQUIRED_ATTRIBUTES: Fields that must be present
#   - FILTER_MAPPINGS: How to translate our query params to upstream params
#
# @example
#   committee = Committee.new(id: "52", data: json_hash)
#   committee.name  # => "Environment, Food and Rural Affairs Committee"
#
class RestApiResource
  attr_reader :id, :data, :resource_type

  def initialize(id:, data:, resource_type: nil)
    @id = id
    @data = data
    @resource_type = resource_type
  end

  def uri
    self.class.construct_uri(id)
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

        json_key = config.is_a?(Hash) ? config[:json_key] : config

        define_method(attr_name) do
          data[json_key]
        end
      end
    end
  end
end
