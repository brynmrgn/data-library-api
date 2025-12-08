# app/models/research_briefing.rb
class ResearchBriefing
  include ApplicationHelper

  TERM_TYPE_MAPPINGS = {
    'subject' => { predicate: 'dc-term:subject', label: 'subject' },
    'topic' => { predicate: '<http://data.parliament.uk/schema/parl#topic>', label: 'topic' },
    'publisher' => { predicate: 'dc-term:publisher', label: 'published by' },
    'section' => { predicate: '<http://data.parliament.uk/schema/parl#section>', label: 'Section' },
    'subtype' => { predicate: '<http://data.parliament.uk/schema/parl#subtype>', label: 'Type' },
    'category' => { predicate: '<http://data.parliament.uk/schema/parl#category>', label: 'Category' }
  }.freeze

    RSS_CONFIG = {
    title: 'UK Parliament Research Briefings',
    description: 'Latest research briefings from the House of Commons Library',
    link_base: 'research-briefings'
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

  attr_reader :id, :data
  
  def initialize(id:, data:)
    @id = id
    @data = data
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
  
  def date
    date_value = data['http://purl.org/dc/terms/date']
    return nil unless date_value.present?
  
    # Handle both string and hash formats
    date_string = date_value.is_a?(Hash) ? date_value["@value"] : date_value
    Date.parse(date_string)
    rescue ArgumentError, TypeError
    nil
  end

  private
  def primary_info_text
    title = data['http://purl.org/dc/terms/title'] || "No title available."
    title
  end
  def secondary_info_text
    publisher = data['http://purl.org/dc/terms/publisher']
    publisherLabel = terms_no_link(publisher) if publisher
    identifier = data['http://purl.org/dc/terms/identifier'] || "No identifier available."
    date = data['http://purl.org/dc/terms/date']
    formatted_date = date ? DateTime.parse(date["@value"]).strftime("%d %B %Y") : ""
    formatted_date + " | " + identifier + " | " + publisherLabel.to_s
  end
  def tertiary_info_text
    description = data['http://purl.org/dc/terms/description'] || "No description available."
    description
  end
  def indicators_left_text
    terms = data['http://data.parliament.uk/schema/parl#topic']
    terms_no_link(terms) if terms
  end
  def indicators_right_text
    #    Empty for research briefings
  end
  
  protected

end