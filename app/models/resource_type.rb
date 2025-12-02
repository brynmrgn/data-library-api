class ResourceType < ApplicationModel
  attribute :id, :string
  attribute :label, :string

  def initialize(id: nil, label: nil)
    super
    @id = id
    @label = label
  end
end
