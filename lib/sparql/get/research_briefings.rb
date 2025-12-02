module Sparql::Get::ResearchBriefings
 
    def get_items(filter = "", offset: nil, limit: nil)
        # a method to get an array of deposited papers (for index page)
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

        list_items = []

        # For each item in the array 
        items.each do |item|
            #  we create a object 
            list_item = DepositedPaper.new
            list_item_id = item['@id']
            list_item_id = list_item_id.sub('http://data.parliament.uk/resources/','')
            list_item.id = list_item_id
            list_item.data_object = item
            #  and add it to the array of deposited papers.
            list_items << list_item
        end

        # We return the array of items
        list_items
    end

    def get_items_count(filter)
        request_body = items_count_query(filter)
        response = Net::HTTP.post( $SPARQL_REQUEST_URI, request_body, $SPARQL_COUNT_HEADERS )
        data = JSON.parse(response.body)
        total = data["results"]["bindings"][0]["total"]["value"].to_i
        
        #We return the count
        total
    end
end