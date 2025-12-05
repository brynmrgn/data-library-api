# app/models/deposited_paper.rb
class DepositedPaper < LinkedDataResource
  include ApplicationHelper
  TERM_TYPE_MAPPINGS = {
    'subject' => { predicate: 'dc-term:subject', label: 'subject' },
    'publisher' => { predicate: 'dc-term:publisher', label: 'published by' },
    'depositing-department' => { predicate: '<http://data.parliament.uk/schema/parl#department>', label: 'deposited by' },
    'corporate-author' => { predicate: '<http://data.parliament.uk/schema/parl#corporateAuthor>', label: 'author' },
    'legislature' => { predicate: '<http://data.parliament.uk/schema/parl#legislature>', label: 'house' } 
    # Add any other term types that deposited papers support
  }.freeze

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
  
  def initialize(id:, data:)
    super(id: id, data: data, resource_type: :deposited_paper)
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
    data['http://purl.org/dc/terms/abstract']
  end 

  def date
  date_received || Time.now # Fallback to current time if no date
  end

  private
  def primary_info_text
    title = data['http://purl.org/dc/terms/abstract'] || "No title available."
    title 
  end
  def secondary_info_text
    identifier = data['http://purl.org/dc/terms/identifier'] || "No identifier available."
    identifier
  end
  def tertiary_info_text
    department = data['http://data.parliament.uk/schema/parl#department']
    terms = terms_no_link(department)
    "Deposited by: #{terms}" if terms
  end
  def indicators_left_text
    date = self.date_received
    date.strftime("Received on: %d %B %Y") if date
  end
  def indicators_right_text
    legislature = data['http://data.parliament.uk/schema/parl#legislature']
    terms = terms_no_link(legislature)
    "House: #{terms}" if terms  
  end
  protected
  
  # Deposited papers sort by date received
  def primary_date
    date_received
  end


end

