require "test_helper"

class DepositedPaperTest < ActiveSupport::TestCase
  def setup
    @item = DepositedPaper.new(
      id: "340587",
      data: sample_deposited_paper_data
    )
  end
  
  test "should have correct id" do
    assert_equal "340587", @item.id
  end
  
  test "should have correct date received" do
    # DepositedPaper uses dateReceived as the primary date
    assert_equal "2024-01-15", @item.data['parl:dateReceived']
  end
  
  test "should have identifier" do
    assert_equal "DEP2024-0001", @item.data['dc-term:identifier']
  end
  
  test "should parse related links correctly from data" do
    links = @item.data['parl:relatedLink']
    assert_equal 1, links.count
    assert_equal "Related Document", links.first['rdfs:label']
    assert_equal "http://example.com/paper-link", links.first['schema:url']['@id']
  end
  
  test "should handle missing related links" do
    @item.data.delete('parl:relatedLink')
    assert_nil @item.data['parl:relatedLink']
  end
  
  test "should have data attribute" do
    assert_not_nil @item.data
    assert_instance_of Hash, @item.data
  end
end