module Sparql::Get::DepositedPaper

    def get_item(item_id, offset: nil, limit: nil)
        # a method to get an array of deposited papers (for index page)
        request_body = list_query( "FILTER (?item IN (<http://data.parliament.uk/depositedpapers/#{item_id}>))", offset: 0, limit: 1)
        frame = item_frame

        # We get the SPARQL response as JSON.
        item_data = get_sparql_response( request_body , frame )
        
        # Return a DepositedPaper object with id and data
        DepositedPaper.new(id: item_id, data: item_data)
    end
end

