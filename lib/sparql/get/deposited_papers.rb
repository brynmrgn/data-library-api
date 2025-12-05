module Sparql::Get::DepositedPapers

    def get_items(filter = "", offset: nil, limit: nil)
        # a method to get an array of deposited papers (for index page)
        request_body = list_query(filter, offset: offset, limit: limit)
        frame = item_frame

        # We get the SPARQL response as JSON.
        data = get_sparql_response(request_body, frame)
        # if only one response, then make array
        items = data['@graph'].presence || [data]

        list_items = items.map do |item|
            list_item_id = item['@id'].sub('http://data.parliament.uk/depositedpapers/', '')
            DepositedPaper.new(id: list_item_id, data: item)
        end

        list_items
    end

    def get_items_count(filter)
        request_body = items_count_query(filter)
        response = Net::HTTP.post( $SPARQL_REQUEST_URI, request_body, $SPARQL_COUNT_HEADERS )  
        data = JSON.parse(response.body)
        total = data["results"]["bindings"][0]["total"]["value"].to_i
  
        # We return the count
        total
    end
end