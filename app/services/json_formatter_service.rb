# app/services/json_formatter_service.rb
#
# Service responsible for formatting LinkedDataResource objects into JSON responses
# Uses model's ATTRIBUTES configuration to determine how to format each field
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
    puts "🔧 #{attr_name} = #{value.inspect[0..50]}" if value.nil?
    next if value.nil?
    
    config = model_attributes[attr_name]
    
    if config.is_a?(Hash) && config[:properties]
      # Nested attribute - always return as array for consistency
      value = [value] unless value.is_a?(Array)
      result[attr_name] = value.map { |v| extract_nested_properties(v, config[:properties]) }
    else
      # Simple value
      result[attr_name] = format_simple_value(value)
    end
  end
  
  result
end
  
  # Formats multiple items for index view
  # @param items [Array<LinkedDataResource>] Items to format
  # @param fields [String, nil] Optional fields parameter ('all' for all attributes)
  #
def self.format_items_for_index(items, attributes:)
  items.map do |item|
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
  
  # Extracts specific properties from a nested object
  # @param obj [Hash] The nested object from the JSON-LD response
  # @param properties [Hash] Map of property names to their predicates
  # @return [Hash] Extracted properties with id
  #
  def self.extract_nested_properties(obj, properties)
    return obj unless obj.is_a?(Hash)
    
    nested = { id: obj['@id'] }
    
    properties.each do |prop_name, predicate|
      nested[prop_name] = obj[predicate] if obj[predicate]
    end
    
    nested
  end
  
  # Unwraps JSON-LD @value/@type structures
  # @param value [Object] The value to format
  # @return [Object] The unwrapped value
  #
  def self.format_simple_value(value)
    if value.is_a?(Hash) && value['@value']
      value['@value']
    else
      value
    end
  end
end