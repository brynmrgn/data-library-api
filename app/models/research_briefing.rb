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
      nested: true,
      nested_predicate: 'rdfs:seeAlso'
    },
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

  # Class method to build URI from ID
  def self.construct_uri(id)
    "http://data.parliament.uk/resources/#{id}"
  end
  
  # THIS IS THE LINE YOU ADD - at the very end, after all constants
  finalize_attributes!
end