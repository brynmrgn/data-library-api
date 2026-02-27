# app/services/json_formatter_service.rb
#
# Formats resource objects into clean JSON API responses.
# Works with both LinkedDataResource (SPARQL) and RestApiResource (REST) items.
#
# Features:
#   - Unwraps JSON-LD @value structures (SPARQL resources)
#   - Extracts nested object properties (topics, authors, etc.)
#   - Sorts nested items (terms alphabetically, sub-objects by position)
#   - Supports index (summary) and show (full) views
#
class JsonFormatterService
  # Formats a single item with specified attributes
  # @param item [LinkedDataResource] The item to format
  # @param attributes_to_include [Array<Symbol>] Which attributes to include (defaults to all)
  # @param include_base_fields [Boolean] Whether to include id/uri (true for index, false for show)
  #
def self.format_item(item, attributes_to_include: nil, include_base_fields: true)
  model_attributes = item.class::ATTRIBUTES
  attributes_to_include ||= model_attributes.keys
    
  result = {}
  
  # Add base fields for index view
  if include_base_fields
    result[:id] = item.id
    result[:uri] = item.class.construct_uri(item.id)
  end
  
  # Add each requested attribute
  attributes_to_include.each do |attr_name|
    value = item.send(attr_name)
    next if value.nil?
    
    config = model_attributes[attr_name]
    
    if config.is_a?(Hash) && config[:properties]
      # Nested attribute - always return as array for consistency
      value = [value] unless value.is_a?(Array)
      formatted = value.map { |v| extract_nested_properties(v, config[:properties]) }
      result[attr_name] = sort_nested_items(formatted, config[:properties])
    else
      # Simple value
      result[attr_name] = format_simple_value(value)
    end
  end
  
  result
end
  
  # Formats multiple items for index view
  # @param items [Array<LinkedDataResource>] Items to format
  # @param all_fields [Boolean] Whether to include all fields or just index attributes
  #
  def self.format_items_for_index(items, all_fields: false)
    items.map do |item|
      attributes = all_fields ? item.class::ATTRIBUTES.keys : item.class::INDEX_ATTRIBUTES
      format_item(item, attributes_to_include: attributes, include_base_fields: true)
    end
  end
  
  # Formats a single item for show (detail) view
  # Returns hash with meta and data sections
  #
  def self.format_item_for_show(item)
    {
      meta: {
        id: item.id,
        type: item.resource_type,
        uri: item.uri
      },
      data: format_item(item, attributes_to_include: item.class::ATTRIBUTES.keys, include_base_fields: false)
    }
  end
  
  private
  
  # Sorts nested items appropriately based on their type
  # - Sub-objects (author, attachment, related_link) have IDs like .../authors/1 - sort by number
  # - Term references (topic, subject, etc.) have IDs like .../terms/12345 - sort by label
  #
  def self.sort_nested_items(items, properties)
    return items if items.empty?

    # Check if this is a term reference (has :label property) or a sub-object
    if properties.key?(:label)
      # Term reference - sort alphabetically by label
      items.sort_by { |v| v[:label].to_s.downcase }
    else
      # Sub-object (author, attachment, etc.) - sort by numeric suffix in ID
      items.sort_by { |v| v[:id].to_s[/\d+$/].to_i }
    end
  end

  # Extracts specific properties from a nested object
  # @param obj [Hash] The nested object (JSON-LD or plain JSON)
  # @param properties [Hash] Map of property names to their keys/predicates
  # @return [Hash] Extracted properties with id
  #
  def self.extract_nested_properties(obj, properties)
    return obj unless obj.is_a?(Hash)
    
    obj_id = obj['@id'] || obj['id']
    nested = obj_id ? { id: obj_id } : {}

    properties.each do |prop_name, key|
      val = obj[key]
      next if val.nil?
      nested[prop_name] = unwrap_value(val)
    end

    nested
  end
  
  # Unwraps JSON-LD @value/@type and @id structures
  # @param value [Object] The value to format
  # @return [Object] The unwrapped value
  #
  def self.format_simple_value(value)
    unwrap_value(value)
  end

  # Unwraps JSON-LD wrappers to plain values
  # { "@value" => "x" } => "x"
  # { "@id" => "http://..." } => "http://..."
  #
  def self.unwrap_value(value)
    if value.is_a?(Hash) && value.key?('@value')
      value['@value']
    elsif value.is_a?(Hash) && value.key?('@id') && value.keys.size == 1
      value['@id']
    else
      value
    end
  end
end