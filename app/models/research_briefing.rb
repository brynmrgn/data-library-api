# app/models/research_briefing.rb
class ResearchBriefing < LinkedDataResource
  include SparqlQueryable
  include PresentationHelpers

  TERM_TYPE_MAPPINGS = {
    'subject' => { predicate: 'dc-term:subject', label: 'subject' },
    'topic' => { predicate: 'parl:topic', label: 'topic' },
    'publisher' => { predicate: 'dc-term:publisher', label: 'published by' },
    'section' => { predicate: 'parl:section', label: 'Section' },
    'subtype' => { predicate: 'parl:subtype', label: 'Type' },
    'category' => { predicate: 'parl:category', label: 'Category' },
      'author' => {
        label: 'Author',
        predicate: 'dc-term:creator',
        nested: true,  # Flag to indicate nested structure
        nested_predicate: 'rdfs:seeAlso'  # The predicate to reach the term
      },
  }.freeze

    RSS_CONFIG = {
    title: 'UK Parliament Research Briefings',
    description: 'Latest research briefings from the House of Commons Library',
    link_base: 'research-briefings'
  }.freeze

  SPARQL_TYPE = '<http://data.parliament.uk/schema/parl#ResearchBriefing>'.freeze

  SORT_BY = :date 
  REQUIRED_ATTRIBUTES = [:title, :identifier].freeze
  INDEX_ATTRIBUTES = [:title, :identifier, :description, :date, :publisher, :topic].freeze

  ATTRIBUTES = {
    # Simple properties
    title: 'dc-term:title',
    identifier: 'dc-term:identifier',
    description: 'dc-term:description',
    date: 'dc-term:date',
    content_location: 'parl:contentLocation',
    external_location: 'parl:externalLocation',
    html_summary: 'parl:htmlsummary',
    
    # Nested objects (with their properties)
    topic: {
      uri: 'parl:topic',
      properties: { label: 'skos:prefLabel' }
    },
    subject: {
      uri: 'dc-term:subject',
      properties: { label: 'skos:prefLabel' }
    },
    publisher: {
      uri: 'dc-term:publisher',
      properties: { label: 'skos:prefLabel' }
    },
    section: {
      uri: 'parl:section',
      properties: { label: 'skos:prefLabel' }
    },
    subtype: {
      uri: 'parl:subtype',
      properties: { label: 'skos:prefLabel' }
    },
    category: {
      uri: 'parl:category',
      properties: { label: 'skos:prefLabel' }
    },
    author: {
      uri: 'dc-term:creator',
      properties: { 
        ses_id: 'rdfs:seeAlso',
        given_name: 'schema:givenName',
        family_name: 'schema:familyName'
      }
    },
    related_link: {
      uri: 'parl:relatedLink',
      properties: {
        url: 'schema:url',
        label: 'rdfs:label'
      }
    },
    attachment: {
      uri: 'parl:attachment',
      properties: {
        title: 'dc-term:title',
        file_url: 'nfo:fileUrl'
      }
    }
  }.freeze

  # Construct the URI for a deposited paper given its ID - this is because of URI structure in triplestore
  def self.construct_uri(id)
    "http://data.parliament.uk/resources/#{id}"
  end

    def card_data
    {
      primary_info: {text: primary_info_text},
      secondary_info: {text: secondary_info_text},
      tertiary_info: {text: tertiary_info_text},
      indicators_left: {text: indicators_left_text},
      indicators_right: {text: indicators_right_text}
    }
  end

  def to_model
    self
  end

  def to_param
    id
  end

  def persisted?
    true
  end

  def model_name
    ActiveModel::Name.new(self.class)
  end

  def self.page_title
    "Research Briefings"
  end
  
  def self.feed_path
    Rails.application.routes.url_helpers.feed_research_briefings_path
  end
    
  # Get display information for RSS feed
  def title
    primary_info_text
  end
  
  def abstract
    tertiary_info_text
  end
  
  def primary_date
    date_value = data['dc-term:date']
    return nil unless date_value.present?
  
    # Handle both string and hash formats
    date_string = date_value.is_a?(Hash) ? date_value["@value"] : date_value
    DateTime.parse(date_string)
    rescue ArgumentError, TypeError
    nil
  end

  def related_links
    links = data['parl:relatedLink']
    return [] if links.nil?
    
    # Normalize to array
    links = [links] unless links.is_a?(Array)
    
    links.map do |link|
      {
        label: link['http://www.w3.org/2000/01/rdf-schema#label'],
        url: link['http://schema.org/url'].is_a?(Hash) ? link['http://schema.org/url']['@id'] : link['http://schema.org/url']
      }
    end.compact
  end

  private
  def primary_info_text
    title = data['dc-term:title'] || "No title available."
    title
  end
  def secondary_info_text
    publisher = data['dc-term:publisher']
    publisherLabel = terms_no_link(publisher) if publisher
    identifier = data['dc-term:identifier'] || "No identifier available."
    date = data['dc-term:date']
    formatted_date = date ? DateTime.parse(date["@value"]).strftime("%d %B %Y") : ""
    formatted_date + " | " + identifier + " | " + publisherLabel.to_s
  end
  def tertiary_info_text
    description = data['dc-term:description'] || "No description available."
    description
  end
  def indicators_left_text
    terms = data['parl:topic']
    return "" unless terms.present?
    result = terms_no_link(terms)
    result  
  end
  def indicators_right_text
    #    Empty for research briefings
  end
  
  protected

end