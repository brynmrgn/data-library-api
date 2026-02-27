# app/services/lda_formatter_service.rb
#
# Formats LinkedDataResource objects into LDA (Linked Data API) format.
# Used by the v0 compatibility API to replicate the legacy response structure.
#
# Replicates the exact output of the existing LDA at eldaddp.azurewebsites.net.
# Field names, wrapping rules, and envelope structure are matched to the real API.
#
class LdaFormatterService
  # Maps v1 attribute names to LDA field names
  FIELD_NAME_MAP = {
    identifier:        "identifier",
    title:             "title",
    description:       "description",
    date:              "date",
    content_location:  "contentLocation",
    external_location: "externalLocation",
    html_summary:      "htmlsummary",
    topic:             "topic",
    subject:           "subject",
    publisher:         "publisher",
    section:           "section",
    subtype:           "subType",
    category:          "category",
    author:            "creator",
    related_link:      "relatedLink",
    attachment:        "attachment",
    abstract:          "abstract",
    created:           "created",
    modified:          "modified",
    published:         "published",
    status:            "status",
    disclaimer:        "disclaimer",
    internal_location: "internalLocation",
    briefing_document: "briefingDocument"
  }.freeze

  # Fields that the LDA returns as plain strings (no wrapping)
  PLAIN_STRING_FIELDS = %i[title html_summary status disclaimer].freeze

  # Fields that the LDA returns as plain string arrays
  PLAIN_ARRAY_FIELDS = %i[description].freeze

  # Fields that are URI references (extract @id to plain string)
  URI_FIELDS = %i[content_location external_location internal_location].freeze

  # Nested fields that the LDA always returns as arrays (even for single items)
  ALWAYS_ARRAY_FIELDS = %i[section].freeze

  # LDA property name overrides for nested objects (where camelize doesn't match)
  LDA_NESTED_NAME_OVERRIDES = {
    related_link: { url: "website", label: "label" },
    attachment: { title: "attachmentTitle", file_size: "sizeOfFile" },
    briefing_document: { title: "attachmentTitle", file_size: "sizeOfFile" }
  }.freeze

  # Nested properties that the LDA returns as plain strings (no _value wrapping)
  LDA_PLAIN_NESTED_FIELDS = {
    attachment: %i[title media_type],
    briefing_document: %i[title media_type]
  }.freeze

  # Nested properties that the LDA returns as integer arrays
  LDA_INTEGER_ARRAY_FIELDS = {
    attachment: %i[file_size],
    briefing_document: %i[file_size]
  }.freeze


  DATE_PATTERN = /\A\d{4}-\d{2}-\d{2}/

  ITEM_TYPE = "http://data.parliament.uk/schema/parl#ResearchBriefing".freeze

  # ---------- Item formatting ----------

  def self.format_items(items)
    items.map { |item| format_item(item) }
  end

  def self.format_item(item)
    model_attributes = item.class::ATTRIBUTES
    result = { "_about" => item.uri }

    model_attributes.each do |attr_name, config|
      value = item.send(attr_name)
      next if value.nil?

      lda_name = FIELD_NAME_MAP[attr_name] || attr_name.to_s

      if config.is_a?(Hash) && config[:properties]
        result[lda_name] = format_nested_value(value, config[:properties], attr_name)
      elsif PLAIN_STRING_FIELDS.include?(attr_name)
        result[lda_name] = extract_raw_value(value)
      elsif PLAIN_ARRAY_FIELDS.include?(attr_name)
        result[lda_name] = [extract_raw_value(value)]
      elsif URI_FIELDS.include?(attr_name)
        result[lda_name] = extract_uri_value(value)
      else
        result[lda_name] = wrap_value(value)
      end
    end

    result["type"] = ITEM_TYPE
    result
  end

  # ---------- Response envelopes ----------

  def self.build_list_envelope(items:, total:, page:, page_size:, request:)
    base_url = "#{request.base_url}#{request.path}"
    request_url = request.original_url
    total_pages = total.zero? ? 1 : (total.to_f / page_size).ceil

    result = {
      "_about" => request_url,
      "definition" => "#{request.base_url}/meta#{request.path}.json",
      "extendedMetadataVersion" => "#{request_url}#{request_url.include?('?') ? '&' : '?'}_metadata=all",
      "first" => "#{base_url}?_page=0",
      "isPartOf" => {
        "_about" => base_url,
        "definition" => "#{request.base_url}/meta#{request.path}.json",
        "hasPart" => request_url,
        "type" => "http://purl.org/linked-data/api/vocab#ListEndpoint"
      },
      "items" => items,
      "itemsPerPage" => page_size,
      "page" => page,
      "startIndex" => (page * page_size) + 1,
      "totalResults" => total,
      "type" => "http://purl.org/linked-data/api/vocab#Page"
    }

    # LDA pagination links only include _page (not _pageSize)
    if page < total_pages - 1
      result["next"] = "#{base_url}?_page=#{page + 1}"
    end

    if page > 0
      result["prev"] = "#{base_url}?_page=#{page - 1}"
    end

    {
      "format" => "linked-data-api",
      "version" => "0.2",
      "result" => result
    }
  end

  def self.build_show_envelope(item:, request:)
    {
      "format" => "linked-data-api",
      "version" => "0.2",
      "result" => {
        "_about" => request.original_url,
        "definition" => "#{request.base_url}/meta#{request.path}.json",
        "extendedMetadataVersion" => "#{request.original_url}?_metadata=all",
        "primaryTopic" => item,
        "type" => [
          "http://purl.org/linked-data/api/vocab#ItemEndpoint",
          "http://purl.org/linked-data/api/vocab#Page"
        ]
      }
    }
  end

  # ---------- Private helpers ----------

  private_class_method

  # Wraps a value in LDA format.
  # Only includes _datatype for dates and booleans, not for plain strings.
  def self.wrap_value(value)
    raw = extract_raw_value(value)
    raw_str = raw.to_s

    if raw_str.match?(DATE_PATTERN)
      { "_value" => raw_str, "_datatype" => "dateTime" }
    elsif raw_str == "true" || raw_str == "false"
      { "_value" => raw_str, "_datatype" => "boolean" }
    else
      { "_value" => raw_str }
    end
  end

  # Extracts the raw value from a possibly JSON-LD wrapped value
  def self.extract_raw_value(value)
    if value.is_a?(Hash) && value['@value']
      value['@value']
    else
      value
    end
  end

  # Extracts a URI from a JSON-LD @id reference
  def self.extract_uri_value(value)
    if value.is_a?(Hash) && value['@id']
      value['@id']
    else
      extract_raw_value(value).to_s
    end
  end

  # Formats nested objects in LDA style.
  # Single objects stay as objects; multiple become an array.
  # Some fields (section) are always arrays even for single items.
  # Term references are sorted alphabetically by prefLabel.
  def self.format_nested_value(value, properties, attr_name)
    items = value.is_a?(Array) ? value : [value]
    formatted = items.map { |v| format_single_nested(v, properties, attr_name) }

    # Sort term references alphabetically by prefLabel (matching LDA)
    if properties.key?(:label) && formatted.length > 1
      formatted.sort_by! { |v| v.is_a?(Hash) && v["prefLabel"] ? v["prefLabel"]["_value"].to_s.downcase : "" }
    end

    if ALWAYS_ARRAY_FIELDS.include?(attr_name)
      formatted
    else
      formatted.length == 1 ? formatted.first : formatted
    end
  end

  # Formats one nested object
  def self.format_single_nested(obj, properties, attr_name)
    return obj unless obj.is_a?(Hash)

    nested = { "_about" => obj['@id'] }
    overrides = LDA_NESTED_NAME_OVERRIDES[attr_name] || {}
    plain_fields = LDA_PLAIN_NESTED_FIELDS[attr_name] || []
    int_array_fields = LDA_INTEGER_ARRAY_FIELDS[attr_name] || []

    properties.each do |prop_name, predicate|
      raw_value = obj[predicate]
      next unless raw_value

      # Use override name if present, otherwise :label → "prefLabel", else camelize
      lda_prop_name = overrides[prop_name] ||
        (prop_name == :label ? "prefLabel" : prop_name.to_s.camelize(:lower))

      if int_array_fields.include?(prop_name)
        nested[lda_prop_name] = [extract_raw_value(raw_value).to_i]
      elsif plain_fields.include?(prop_name)
        nested[lda_prop_name] = extract_raw_value(raw_value)
      elsif raw_value.is_a?(Hash) && raw_value['@id']
        nested[lda_prop_name] = raw_value['@id']
      else
        nested[lda_prop_name] = wrap_value(raw_value)
      end
    end

    # Creator gets a type field in LDA
    if attr_name == :author
      nested["type"] = "http://schema.org/Person"
    end

    nested
  end

  def self.build_page_url(base_url, page, page_size)
    url_params = { "_page" => page }
    url_params["_pageSize"] = page_size if page_size != 10
    "#{base_url}?#{url_params.to_query}"
  end
end
