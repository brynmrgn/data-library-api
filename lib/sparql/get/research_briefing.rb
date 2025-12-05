module Sparql::Get::ResearchBriefing

  def get_item(item_id, offset: nil, limit: nil)
    # a method to get a single research briefing (for show page)
    request_body = list_query("FILTER (?item IN (<http://data.parliament.uk/resources/#{item_id}>))", offset: 0, limit: 1)
    frame = item_frame

    # We get the SPARQL response as JSON.
    item_data = get_sparql_response(request_body, frame)
    
    # Return a ResearchBriefing object with id and data
    ResearchBriefing.new(id: item_id, data: item_data)
  end
end

