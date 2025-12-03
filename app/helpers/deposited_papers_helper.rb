module DepositedPapersHelper

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

end
