# app/services/sparql_get_object.rb
class SparqlGetObject
  def self.get_items(type_key, filter, limit:, offset:)
    model_class = get_model_class(type_key)

    query = SparqlQueryService.build_query(model_class, filter, limit, offset)
    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class,
      'index'  # Pass context type for frame generation
    )

    puts "Response status: #{response.code}"
    puts "Response body: #{response.body[0..1000]}"
    
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("SPARQL request failed: #{response.code} #{response.body}")
      return []
    end
    
    results = JSON.parse(response.body)

    puts "Parsed results keys: #{results.keys}"
    puts "Results @graph: #{results['@graph'].inspect[0..500]}"

    instantiate_items(results, type_key)
  end

  def self.get_item(type_key, id)
    puts "get_item: type_key=#{type_key.inspect}, id=#{id}"
    model_class = get_model_class(type_key)
    puts "get_item: model_class=#{model_class}"
    query_module = model_class::QUERY_MODULE
    
    item_uri = model_class.construct_uri(id)
    filter = "FILTER(?item = <#{item_uri}>)"
    
    query = query_module.show_query(model_class, filter)
    
    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class,
      'show'  # Pass context type for frame generation
    )
    
    puts "get_item: response.code=#{response.code}"
    puts "get_item: response.body length=#{response.body.length}"
    
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("SPARQL item request failed: #{response.code} #{response.body}")
      return nil
    end
    
    results = JSON.parse(response.body)
    
    # Wrap single item in @graph for consistency with get_items
    results = { "@graph" => [results] } unless results['@graph']
    
    puts "get_item: results['@graph']=#{results['@graph'].inspect[0..500]}"
    
    items = instantiate_items(results, type_key)
    puts "get_item: items=#{items.inspect}"
    
    items.first
  end

  private

  def self.instantiate_items(results, type_key)
    model_class = get_model_class(type_key)
    
    items_array = results['@graph'] || []
    puts "instantiate_items: Got #{items_array.length} items from @graph"
    
    items_array.map do |result|
      item_uri = result['@id']
      
      unless item_uri
        puts "Missing @id in result: #{result.inspect}"
        next
      end
      
      id = item_uri.split('/').last
      puts "instantiate_items: Creating #{model_class} with id=#{id}"
    
      item = model_class.new(
        id: id,
        data: result,
        resource_type: type_key
      )
      puts "instantiate_items: Created item with title=#{item.title}"
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