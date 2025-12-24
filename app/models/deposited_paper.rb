# app/models/deposited_paper.rb
class DepositedPaper < LinkedDataResource
  include SparqlQueryable
  include PresentationHelpers

  TERM_TYPE_MAPPINGS = {
    'subject' => { predicate: 'dc-term:subject', label: 'subject' },
    'publisher' => { predicate: 'dc-term:publisher', label: 'published by' },
    'depositing-department' => { predicate: 'parl:department', label: 'deposited by' },
    'corporate-author' => { predicate: 'parl:corporateAuthor', label: 'author' },
    'legislature' => { predicate: 'parl:legislature', label: 'house' } 
    # Add any other term types that deposited papers support
  }.freeze
  
  SPARQL_TYPE = '<http://data.parliament.uk/schema/parl#DepositedPaper>'.freeze
 
  REQUIRED_ATTRIBUTES = [:abstract, :identifier, :dateReceived].freeze
  INDEX_ATTRIBUTES = [:abstract, :identifier, :depositingDepartment, :dateReceived, :legislature].freeze
  SORT_BY = :dateReceived  

  ATTRIBUTES = {
    title: 'dc-term:title',
    identifier: 'dc-term:identifier',
    abstract: 'dc-term:abstract',
    dateReceived: 'parl:dateReceived',
    lastModified: 'parl:dateLastModified',
    dateOfOrigin: 'parl:dateOfOrigin',
    dateOfCommitmentToDeposit: 'parl:dateOfCommitmentToDeposit',
    corporateAuthor: {
      uri: 'parl:corporateAuthor',
      properties: {
        label: 'skos:prefLabel'
      }
    },
    subject: {
      uri: 'dc-term:subject',
      properties: {
        label: 'skos:prefLabel'
      }
    },
    depositingDepartment: {
      uri: 'parl:department',
      properties: {
        label: 'skos:prefLabel'
      }
    },
    depositedFile: 'parl:depositedFile',
    indexingStatus: 'parl:indexStatus',
    legislature: {
      uri: 'parl:legislature',
      properties: {
        label: 'skos:prefLabel'
      }
      },
    relation: {
      uri: 'dc-term:relation',
      properties: {
        externalLocation: 'parl:externalLocation',
        title: 'dc-term:title'
      }
    }
  }.freeze
  
    # Class method to build URI from ID
  def self.construct_uri(id)
    "http://data.parliament.uk/depositedpapers/#{id}"
  end
  
  # Generate accessor methods from ATTRIBUTES
  finalize_attributes!
end

