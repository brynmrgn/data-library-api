require "test_helper"

class ResearchBriefingTest < ActiveSupport::TestCase
  def setup
    @item = ResearchBriefing.new(
      id: "344893",
      data: sample_research_briefing_data
    )
  end
  
  test "should have correct id" do
    assert_equal "344893", @item.id
  end
  
  test "should have correct title" do
    assert_equal "Apprenticeship statistics (England)", @item.title
  end
  
    test "should have correct date" do
    # Your model returns a Date object, not a string
    assert_equal Date.parse("2024-12-06"), @item.date
    end
  
test "should have correct abstract" do
  # Make sure your sample data has the abstract
  assert_equal "Statistics on apprenticeships in England", @item.data['dc-term:abstract']
end
  
  test "should parse related links correctly from data" do
    links = @item.data['parl:relatedLink']
    assert_equal 2, links.count
    assert_equal "Link 1", links.first['rdfs:label']
    assert_equal "http://example.com/link1", links.first['schema:url']['@id']
  end
  
  test "should handle multiple related links" do
    links = @item.data['parl:relatedLink']
    assert_equal 2, links.count
    assert_equal "Link 2", links.last['rdfs:label']
    assert_equal "http://example.com/link2", links.last['schema:url']['@id']
  end
  
  test "should parse author data" do
    creator = @item.data['dc-term:creator']
    assert_equal "Matthew", creator['schema:givenName']
    assert_equal "Ward", creator['schema:familyName']
  end
  
  test "should parse subject terms" do
    subjects = @item.data['dc-term:subject']
    assert_equal 2, subjects.count
    assert_equal "Apprentices", subjects.first['skos:prefLabel']
  end
  
  test "should have data attribute" do
    assert_not_nil @item.data
    assert_instance_of Hash, @item.data
  end
end