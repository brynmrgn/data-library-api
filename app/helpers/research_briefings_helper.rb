module ResearchBriefingsHelper

    def terms_no_link ( terms )
        terms2 = terms
        if terms.class.name == "Hash"
            terms = []
            terms << terms2
        end
        terms_text = ""
        #terms.each do |term|
        #    terms_text += term ['http://www.w3.org/2004/02/skos/core#prefLabel']
        #    terms_text += ", "
        #end
        terms_text = terms
            .map { |t| t['http://www.w3.org/2004/02/skos/core#prefLabel'] }
            .compact
            .join(', ')
        terms_text
    end 

    def terms_with_link ( terms , object_type)
        terms2 = terms
        if terms.class.name == "Hash"
            terms = []
            terms << terms2
        end
        terms_text = ""
        #terms.each do |t|
        #    term_id = t['@id'].gsub('http://data.parliament.uk/terms/','')
        #    terms_text += link_to t['http://www.w3.org/2004/02/skos/core#prefLabel'], deposited_papers_path + '/' + object_type +'/' + term_id
        #    terms_text += " "
        links = terms.filter_map do |t|
            label  = t['http://www.w3.org/2004/02/skos/core#prefLabel'].to_s.presence
            next unless label
            term_id = t['@id'].to_s.sub(%r{\Ahttp://data\.parliament\.uk/terms/}, '')
            link_to(label, "#{research_briefings_path}/#{object_type}/#{term_id}")
        end
        terms_text = safe_join(links, ', ')     # or ', ' for commas, 
        terms_text
    end
end
