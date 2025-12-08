# app/services/sparql_get_object.rb
# Orchestrates: builds query → executes it → instantiates models
# Controller
#  ↓
#SparqlGetObject.get_items() 
#  ↓
#  calls SparqlQueryService.build_query() → gets query string
#  ↓
#  calls SparqlHttpHelper.execute_sparql_post() → gets results
#  ↓
#  instantiates models and returns them

# app/services/sparql_get_object.rb
class SparqlGetObject
  def self.get_items(type_key, filter, limit:, offset:)
    model_class = get_model_class(type_key)  # MOVE THIS UP

    query = SparqlQueryService.build_query(model_class, filter, limit, offset)
    response = SparqlHttpHelper.execute_sparql_post(
      $SPARQL_REQUEST_URI,
      query,
      $SPARQL_REQUEST_HEADERS,
      model_class
    )
    
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("SPARQL request failed: #{response.code} #{response.body}")
      return []
    end
    
    results = JSON.parse(response.body)  # Parse the response body here

    instantiate_items(results, type_key)
  end

  def self.get_item(type_key, id)
  model_class = get_model_class(type_key)
  query_module = model_class::QUERY_MODULE
  
  # Use model's construct_uri method
  item_uri = model_class.construct_uri(id)
  filter = "FILTER(?item = <#{item_uri}>)"
  
  query = query_module.list_query(filter, offset: 0, limit: 1)
  response = SparqlHttpHelper.execute_sparql_post(
    $SPARQL_REQUEST_URI,
    query,
    $SPARQL_REQUEST_HEADERS,
    model_class
  )
  
  unless response.is_a?(Net::HTTPSuccess)
    Rails.logger.error("SPARQL item request failed: #{response.code} #{response.body}")
    return nil
  end
  
  results = JSON.parse(response.body)
  instantiate_items(results, type_key).first
end

  private

def self.instantiate_items(results, type_key)
  model_class = get_model_class(type_key)
  
  # Handle framed JSON-LD structure
  items_array = if results.is_a?(Hash) && results['@graph'].is_a?(Array)
    results['@graph']
  elsif results.is_a?(Hash) && results['@id']
    # Single framed item (not wrapped in @graph)
    [results]
  elsif results.is_a?(Array)
    results
  else
    []
  end
  
  items_array.map do |result|
    item_uri = result['@id']
    
    unless item_uri
      Rails.logger.warn("Missing @id in result: #{result.inspect}")
      next
    end
    
    id = item_uri.split('/').last
  
    model_class.new(
      id: id,
      data: result,
      resource_type: type_key
    )
  end.compact
end

  def self.get_model_class(type_key)
    class_name = type_key.to_s.classify
    model_class = class_name.constantize
    raise ArgumentError, "Unknown type: #{type_key}" unless model_class < LinkedDataResource
    model_class
  end
end