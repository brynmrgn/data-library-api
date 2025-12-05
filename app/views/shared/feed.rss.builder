xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    rss_config = @model_class::RSS_CONFIG
    
    xml.title rss_config[:title] + @title
    xml.description rss_config[:description]
    xml.link request.original_url

    @items.each do |item|
      xml.item do
        xml.title item.title
        xml.description item.abstract if item.respond_to?(:abstract)
        xml.pubDate item.date.to_time.rfc822 if item.date.present?
        xml.link "#{request.base_url}/#{rss_config[:link_base]}/#{item.id}"
        xml.guid "#{request.base_url}/#{rss_config[:link_base]}/#{item.id}"
      end
    end
  end
end