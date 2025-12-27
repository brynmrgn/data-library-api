# app/services/pagination_builder.rb
#
# Builds pagination metadata for API responses
#
class PaginationBuilder
  # Builds pagination metadata hash from Pagy object
  #
  # @param pagy [Pagy] Pagination object
  # @param model_class [Class] The model class for type info
  # @param items_count [Integer] Number of items in current response
  # @return [Hash] Pagination metadata
  #
  def self.build_metadata(pagy, model_class, items_count)
    {
      total: pagy.count,
      page: pagy.page,
      per_page: pagy.limit,
      total_pages: pagy.pages,
      items_in_response: items_count,
      type: model_class.name.underscore
    }
  end
end