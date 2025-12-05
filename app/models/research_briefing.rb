# app/models/research_briefing.rb
class ResearchBriefing
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
  # Get display information for cards and detail views
  def primary_info
    {
      text: data['http://purl.org/dc/terms/title'] || "No title available."
    }
  end
  
  def secondary_info
    publisher = data['http://purl.org/dc/terms/publisher']
    identifier = data['http://purl.org/dc/terms/identifier']
    date = data['http://purl.org/dc/terms/date']
    formatted_date = date ? DateTime.parse(date["@value"]).strftime("%d %B %Y") : ""
    description = data['http://purl.org/dc/terms/description'] || "No Description"
    
    {
      # Concatenate publisher, identifier, and date with pipes
      metadata: { publisher: publisher, identifier: identifier, date: formatted_date },
      description: description,
      format: :terms_no_link  # for the publisher
    }
  end
  
  def tertiary_info
    {
      # Empty for research briefings
    }
  end
  
  def indicators_left
    {
      label: "Topics",
      value: data['http://data.parliament.uk/schema/parl#topic'],
      default: "No Topics",
      format: :terms_no_link
    }
  end
  
  def indicators_right
    {
      # Empty for research briefings
    }
  end
  
  # Get display information for RSS feed
  def title
    primary_info[:text]
  end
  
  def abstract
    secondary_info[:description]
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
  protected
end