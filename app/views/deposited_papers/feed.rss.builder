# app/views/deposited_papers/feed.rss.builder
xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title "UK Parliament Deposited Papers"
    xml.description "Latest deposited papers from the UK Parliament"
    xml.link deposited_papers_url
    xml.language "en-gb"
    xml.lastBuildDate @items.first&.date&.to_fs(:rfc822) || Time.current.to_fs(:rfc822)

    @items.each do |item|
      xml.item do
        xml.title item.title || "Deposited Paper #{item.id}"
        xml.link url_for(controller: 'deposited_papers', action: 'show', id: item.id, only_path: false)
        xml.description item.summary || item.title || "View details"
        xml.pubDate item.date&.to_fs(:rfc822) || Time.current.to_fs(:rfc822)
        xml.guid url_for(controller: 'deposited_papers', action: 'show', id: item.id, only_path: false), isPermaLink: true
      end
    end
  end
end