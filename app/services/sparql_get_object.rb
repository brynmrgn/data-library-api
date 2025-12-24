# app/services/sparql_get_object.rb
class SparqlGetObject
  def self.get_items(type_key, filter, limit:, offset:, attributes:)
    model_class = get_model_class(type_key)
    
    query = SparqlQueryService.build_query(model_class, filter, limit, offset, attributes)
   
    puts "[SPARQL get_item] #{model_class.name} "
    puts "[SPARQL get_item] Query:\n#{query}"

    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class,
      attributes
    )
    
    unless response.is_a?(Net::HTTPSuccess)
      return []
    end
    
    results = JSON.parse(response.body)

    instantiate_items(results, type_key)
  end

  def self.get_item(type_key, id, attributes: nil)
    model_class = get_model_class(type_key)
    attributes ||= model_class::ATTRIBUTES.keys  # Default to all if not provided
    query_module = model_class::QUERY_MODULE
    
    item_uri = model_class.construct_uri(id)
    filter = "FILTER(?item = <#{item_uri}>)"
    
    query = query_module.show_query(model_class, filter)

    puts "[SPARQL get_item] #{model_class.name} id=#{id}, uri=#{item_uri}"
    puts "[SPARQL get_item] Query:\n#{query}"
    
    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class,
      attributes  # Use provided/all attributes for JSON-LD framing
    )

    puts "[SPARQL get_item] HTTP #{response.code} for #{model_class.name} id=#{id}"
    
    unless response.is_a?(Net::HTTPSuccess)
      puts "[SPARQL get_item] ERROR #{response.code} #{response.body}"
      return nil
    end
    
    puts "[SPARQL get_item] Raw response body (truncated): #{response.body[0..1000]}"

    results = JSON.parse(response.body)
    
    # Wrap single item in @graph for consistency with get_items
    results = { "@graph" => [results] } unless results['@graph']
        
    items = instantiate_items(results, type_key)

    puts "[SPARQL get_item] Instantiated #{items.length} items for #{model_class.name} id=#{id}"
    
    items.first
  end

  private

  def self.instantiate_items(results, type_key)
    model_class = get_model_class(type_key)
    
    items_array = results['@graph'] || []
    
    items_array.map do |result|
      item_uri = result['@id']
      
      unless item_uri
        next
      end
      
      id = item_uri.split('/').last
    
      item = model_class.new(
        id: id,
        data: result,
        resource_type: type_key
      )
      item
    end.compact.tap { |items| puts "instantiate_items: Returning #{items.length} items" }
  end

  def self.get_model_class(type_key)
    class_name = type_key.to_s.classify
    model_class = class_name.constantize
    raise ArgumentError, "Unknown type: #{type_key}" unless model_class < LinkedDataResource
    model_class
  end
end