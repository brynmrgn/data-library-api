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
  
  QUERY_MODULE = Sparql::Queries::Base
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
  
  # Construct the URI for a deposited paper given its ID - this is because of URI structure in triplestore
  def self.construct_uri(id)
    "http://data.parliament.uk/depositedpapers/#{id}"
  end

  RSS_CONFIG = {
    title: 'UK Parliament Deposited Papers',
    description: 'Latest deposited papers from the UK Parliament',
    link_base: 'deposited-papers'
  }.freeze

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
    "Deposited Papers"
  end
  
  def self.feed_path
    Rails.application.routes.url_helpers.feed_deposited_papers_path
  end

  # Get display information for RSS feed
  def abstract
    data['dc-term:abstract']
  end 

  def title
    data['dc-term:identifier']
  end

  def primary_date
    date_received || Time.now # Fallback to current time if no date
  end

  private

  def primary_info_text
    title = data['dc-term:abstract'] || "No title available."
    title 
  end
  def secondary_info_text
    identifier = data['dc-term:identifier'] || "No identifier available."
    identifier
  end
  def tertiary_info_text  
    department = data['parl:department']
    terms = terms_no_link(department)
    "Deposited by: #{terms}" if terms
  end

def indicators_left_text
  date = extract_date('parl:dateReceived')
  return "" unless date
  
  date.strftime("Received on: %d %B %Y")
end
  
  def indicators_right_text
    legislature = data['parl:legislature']
    terms = terms_no_link(legislature)
    "House: #{terms}" if terms  
  end
  protected
  
  # Deposited papers sort by date received
  def primary_date
    date_received
  end


end

