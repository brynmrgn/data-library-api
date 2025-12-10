module PresentationHelpers
  
    def terms_with_link(terms, type = nil, path = nil)
        return "" unless terms
  
  # Normalize to array if it's a single Hash
  terms = [terms] if terms.is_a?(Hash)
  
  links = terms.filter_map do |t|
    label = t['skos:prefLabel'].to_s.presence
    next unless label
    term_id = t['@id'].to_s.sub(%r{\Ahttp://data\.parliament\.uk/terms/}, '')
    
    "<a href=\"/terms/#{term_id}\">#{label}</a>"
  end
  
  links.join(", ").html_safe
    
end

    def terms_no_link(terms)
        return "" if terms.nil?
        
        # If it's a single hash, wrap it in an array
        terms = [terms] if terms.is_a?(Hash)
        
        terms = Array(terms).compact
        terms
            .map { |t| t.is_a?(Hash) ? t['skos:prefLabel'] : nil }
            .compact
            .join(', ')
    end

def authors_with_link
  # Use dc-term:creator for research briefings
  authors = data['dc-term:creator'] || data['parl:author'] || data['schema:author']
  
  return '' if authors.blank?
  
  # Ensure it's an array
  authors = [authors] unless authors.is_a?(Array)
  
  author_links = authors.filter_map do |author|
    given_name = author['schema:givenName']
    family_name = author['schema:familyName']
    
    # Skip if no name data
    next nil if given_name.blank? && family_name.blank?
    
    # Build full name
    full_name = [given_name, family_name].compact.join(' ')
    
    # Check if there's a seeAlso ID for filtering
    see_also = author['rdfs:seeAlso']
    
    if see_also && see_also['@id']
      # Extract the term ID from the URI
      term_id = see_also['@id'].split('/').last
      controller_name = self.class.name.underscore.pluralize.dasherize
      
      # Build the link manually, matching your route structure
      "<a href=\"/#{controller_name}/author/#{term_id}\">#{full_name}</a>"
    else
      # No ID, just return the name as plain text
      full_name
    end
  end
  
  author_links.join(', ').html_safe
end
end