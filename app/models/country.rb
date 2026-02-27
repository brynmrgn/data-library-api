  # app/models/country.rb
  # AUTO-GENERATED from config/models.yml - Do not edit!
  # Run: rake generate:models

  class Country < RestApiResource
    BASE_URL = "https://committees-api.parliament.uk".freeze
    API_PATH = "/api/Countries".freeze
    ID_FIELD = "id".freeze

    DEFAULT_SORT_FIELD = :name
    DEFAULT_SORT_ORDER = :asc
    SORTABLE_FIELDS = [:name].freeze

    ATTRIBUTES = {
  :name => "text",
  :iso_code => "isoCode",
  :display_order => "displayOrder"
}.freeze

    INDEX_ATTRIBUTES = [:name, :iso_code].freeze
    REQUIRED_ATTRIBUTES = [:name].freeze

    TERM_TYPE_MAPPINGS = {}.freeze

    FILTER_MAPPINGS = {}.freeze

    API_RESPONSE_FORMAT = "array".freeze

    def self.construct_uri(id)
      "#{BASE_URL}#{API_PATH}/#{id}"
    end

    finalize_attributes!
  end
