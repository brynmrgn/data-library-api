# app/models/linked_data_resource.rb
class LinkedDataResource
  attr_reader :id, :data, :resource_type
  
  def initialize(id:, data:, resource_type: nil)
    @id = id  # Numeric ID extracted from URI
    @data = data
    @resource_type = resource_type
  end
  
  # URI is the full @id from the data
  def uri
    data['@id']
  end
  
  alias_method :item_uri, :uri
  
  # Auto-generate accessor methods from ATTRIBUTES constant
  def self.inherited(subclass)
    super
    
    subclass.define_singleton_method(:finalize_attributes!) do
      return unless const_defined?(:ATTRIBUTES)
      
      self::ATTRIBUTES.each do |attr_name, config|
        next if method_defined?(attr_name)
        
        predicate = config.is_a?(Hash) ? config[:uri] : config
        
        define_method(attr_name) do
          data[predicate]
        end
      end
    end
  end
end