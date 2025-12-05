module Sparql::Get::ResearchBriefings
  include SparqlHttpHelper
 
  def get_items(filter = "", offset: nil, limit: nil)
    # a method to get an array of research briefings (for index page)
    request_body = list_query(filter, offset: offset, limit: limit)
    frame = item_frame

    # We get the SPARQL response as JSON.
    data = get_sparql_response(request_body, frame)
    
    # if only one response, then make array
    if data['@graph']
      items = data['@graph']
    else
      items = []
      items << data
    end

    # Map each item to a ResearchBriefing object
    list_items = items.map do |item|
      list_item_id = item['@id'].sub('http://data.parliament.uk/resources/', '')
      ResearchBriefing.new(id: list_item_id, data: item)
    end

    # We return the array of items
    list_items
  end

  def get_items_count(filter)
    request_body = items_count_query(filter)
    response = sparql_post($SPARQL_REQUEST_URI, request_body, $SPARQL_COUNT_HEADERS)
    data = JSON.parse(response.body)
    total = data["results"]["bindings"][0]["total"]["value"].to_i
  end
end