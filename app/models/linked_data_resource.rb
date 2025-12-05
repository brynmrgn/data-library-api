# app/models/linked_data_resource.rb
class LinkedDataResource
  attr_reader :id, :data, :resource_type
  
  def initialize(id:, data:, resource_type: nil)
    @id = id
    @data = data
    @resource_type = resource_type
  end
  
  # Common fields
  def title
    data["http://www.w3.org/2000/01/rdf-schema#label"] || 
    data["http://purl.org/dc/terms/title"] ||
    data["title"] ||
    default_title
  end
  
  # Primary date - override in subclasses to define sorting date
  def date
    primary_date || fallback_date
  end
  
  # Get a specific date type
  def date_received
    extract_date("http://data.parliament.uk/schema/parl#dateReceived", "date_received")
  end
  
  def date_published
    extract_date("http://purl.org/dc/terms/issued", "date_published", "published_at")
  end
  
  def date_created
    extract_date("http://purl.org/dc/terms/created", "date_created", "created_at")
  end
  
  def date_modified
    extract_date("http://purl.org/dc/terms/modified", "date_modified", "updated_at")
  end
  
  def link
    data["http://data.parliament.uk/schema/parl#webLink"] ||
    data["http://www.w3.org/2000/01/rdf-schema#seeAlso"] ||
    data["link"] ||
    data["url"]
  end
  
  def summary
    data["http://purl.org/dc/terms/abstract"] ||
    data["http://purl.org/dc/terms/description"] ||
    data["summary"] ||
    data["description"]
  end
  
  def author
    data["http://purl.org/dc/terms/creator"] ||
    data["http://data.parliament.uk/schema/parl#depositingBody"] ||
    data["author"] ||
    data["creator"]
  end
  
  # Aliases for backward compatibility
  alias_method :deposited_at, :date
  alias_method :published_at, :date
  alias_method :created_at, :date

  def partial_path
    case self.class.name
        when 'DepositedPaper'
            'deposited_papers/card'
        when 'ResearchBriefing'
            'research_briefings/card'
    end
  end
  
  protected
  
  # Override this in subclasses to define the "primary" date for sorting
  def primary_date
    nil
  end
  
  # Fallback tries all common date fields
  def fallback_date
    date_received || date_published || date_created || date_modified
  end


  
  private
  
  def extract_date(*keys)
    raw = keys.map { |key| data[key] }.compact.first
    parse_date(raw) if raw
  end
  
  def default_title
    "#{resource_type_label} #{id}"
  end
  
  def resource_type_label
    resource_type&.to_s&.titleize || "Resource"
  end
  
  def parse_date(date_string)
    return date_string if date_string.is_a?(Time) || date_string.is_a?(Date)
    Time.parse(date_string.to_s)
  rescue ArgumentError
    nil
  end


end