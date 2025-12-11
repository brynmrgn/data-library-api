# app/models/linked_data_resource.rb
class LinkedDataResource
    include SparqlHttpHelper
    require 'cgi'

    QUERY_MODULE = SparqlQueryBuilder

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

  def item_uri
    data['@id']
  end
  
  # Primary date - override in subclasses to define sorting date
  def date
    primary_date || fallback_date
  end
  
  # Get a specific date type
  def date_received
    extract_date("parl:dateReceived", "date_received")
  end
  
  def date_published
    extract_date("dc-term:issued", "date_published", "published_at")
  end
  
  def date_created
    extract_date("dc-term:created", "date_created", "created_at")
  end
  
  def date_modified
    extract_date("dc-term:modified", "date_modified", "updated_at")
  end
  
  def link
    data["parl:webLink"] ||
    data["http://www.w3.org/2000/01/rdf-schema#seeAlso"] ||
    data["link"] ||
    data["url"]
  end
  
  def summary
    data["dc-term:abstract"] ||
    data["dc-term:description"] ||
    data["summary"] ||
    data["description"]
  end
  
  def author
    data["dc-term:creator"] ||
    data["parl:depositingBody"] ||
    data["author"] ||
    data["creator"]
  end
  
  # Aliases for backward compatibility
  alias_method :deposited_at, :date
  alias_method :published_at, :date
  alias_method :created_at, :date
  
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
  
  def parse_date(raw)
    # Extract @value if it's a Hash
    raw = raw['@value'] if raw.is_a?(Hash)
    
    # Parse the string to DateTime
    DateTime.parse(raw) if raw.is_a?(String)
  end


end