require "test_helper"

class Api::V0::ResearchBriefingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @sample_data = sample_research_briefing_data.merge(
      "dc-term:identifier" => "CBP-1234",
      "dc-term:description" => "A test description"
    )
    @sample_item = ResearchBriefing.new(id: "344893", data: @sample_data, resource_type: :research_briefing)
  end

  # --- Index endpoint ---

  test "index returns LDA envelope structure" do
    stub_sparql_services(items: [@sample_item], count: 1)

    get "/api/v0/research-briefings"

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "linked-data-api", json["format"]
    assert_equal "0.2", json["version"]
    assert json.key?("result"), "Response should have result key"
    assert json["result"].key?("items"), "Result should have items"
    assert_equal 1, json["result"]["totalResults"]
  end

  test "index items use LDA format with _about and wrapped values" do
    stub_sparql_services(items: [@sample_item], count: 1)

    get "/api/v0/research-briefings"

    json = JSON.parse(response.body)
    item = json["result"]["items"].first

    assert item.key?("_about"), "Item should have _about"
    assert_equal "http://data.parliament.uk/resources/344893", item["_about"]
    assert_instance_of String, item["title"], "Title should be a plain string"
    assert item.key?("type"), "Item should have type array"
  end

  test "index uses identifier field name" do
    stub_sparql_services(items: [@sample_item], count: 1)

    get "/api/v0/research-briefings"

    json = JSON.parse(response.body)
    item = json["result"]["items"].first

    assert item.key?("identifier"), "Should use LDA field name identifier"
  end

  test "index defaults to page 0 and pageSize 10" do
    stub_sparql_services(items: [], count: 0)

    get "/api/v0/research-briefings"

    json = JSON.parse(response.body)
    assert_equal 0, json["result"]["page"]
    assert_equal 10, json["result"]["itemsPerPage"]
  end

  test "index respects _page and _pageSize params" do
    stub_sparql_services(items: [], count: 100)

    get "/api/v0/research-briefings", params: { _page: 2, _pageSize: 25 }

    json = JSON.parse(response.body)
    assert_equal 2, json["result"]["page"]
    assert_equal 25, json["result"]["itemsPerPage"]
  end

  test "index caps _pageSize at 500" do
    stub_sparql_services(items: [], count: 100)

    get "/api/v0/research-briefings", params: { _pageSize: 1000 }

    json = JSON.parse(response.body)
    assert_equal 500, json["result"]["itemsPerPage"]
  end

  test "index includes pagination links" do
    stub_sparql_services(items: [], count: 100)

    get "/api/v0/research-briefings"

    json = JSON.parse(response.body)
    result = json["result"]
    assert result.key?("first"), "Should have first link"
    assert result.key?("next"), "Should have next link when more pages exist"
  end

  test "index sets cache-control header" do
    stub_sparql_services(items: [], count: 0)

    get "/api/v0/research-briefings"

    assert_match(/max-age=300/, response.headers["Cache-Control"])
  end

  # --- Show endpoint ---

  test "show returns LDA envelope with primaryTopic" do
    stub_sparql_show(item: @sample_item)

    get "/api/v0/research-briefings/344893"

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "linked-data-api", json["format"]
    assert_equal "0.2", json["version"]
    assert json["result"].key?("primaryTopic"), "Should wrap item in primaryTopic"
  end

  test "show primaryTopic uses LDA format" do
    stub_sparql_show(item: @sample_item)

    get "/api/v0/research-briefings/344893"

    json = JSON.parse(response.body)
    item = json["result"]["primaryTopic"]

    assert item.key?("_about"), "Item should have _about"
    assert_instance_of String, item["title"], "Title should be a plain string"
    assert item.key?("type"), "Item should have type"
  end

  test "show returns 404 for missing item" do
    stub_sparql_show(item: nil)

    get "/api/v0/research-briefings/999999"

    assert_response :not_found
  end

  test "show sets cache-control header" do
    stub_sparql_show(item: @sample_item)

    get "/api/v0/research-briefings/344893"

    assert_match(/max-age=900/, response.headers["Cache-Control"])
  end

  private

  def stub_sparql_services(items:, count:)
    SparqlItemsCount.stubs(:get_items_count).returns(count)
    SparqlGetObject.stubs(:get_items).returns({ items: items, query: "CONSTRUCT { ... }" })
  end

  def stub_sparql_show(item:)
    SparqlGetObject.stubs(:get_item).returns({ item: item, query: "CONSTRUCT { ... }" })
  end
end
