class DepositedPaper < ApplicationModel
  attribute :id, :string
  attribute :data_object

  def initialize(id: nil, data_object: nil)
    super
    @id = id
    @data_object = data_object
  end
end
