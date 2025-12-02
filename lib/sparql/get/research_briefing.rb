module Sparql::Get::ResearchBriefing

    def get_item (item_id, offset: nil, limit: nil)
        # a method to get an array of deposited papers (for index page)
        request_body = list_query( "FILTER (?item IN (<http://data.parliament.uk/resources/#{item_id}>))", offset: 0, limit: 1)
        frame = item_frame

        # We get the SPARQL response as JSON.
        item = get_sparql_response( request_body , frame )
        
        list_item = DepositedPaper.new
        list_item.data_object = item 
        list_item
    end
end

