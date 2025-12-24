# app/services/pagination_builder.rb
#
# Service responsible for building pagination metadata and links
#
class PaginationBuilder
  
  # Builds pagination metadata hash
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
  
  # Builds pagination links hash
  #
  def self.build_links(pagy, request, params)
    {
      self: request.original_url,
      first: build_url(params, page: 1),
      last: build_url(params, page: pagy.pages),
      next: pagy.next ? build_url(params, page: pagy.next) : nil,
      prev: pagy.prev ? build_url(params, page: pagy.prev) : nil
    }.compact
  end
  
  private
  
  def self.build_url(params, overrides)
    # Pass the URL helper context or build URLs differently
    # This is a placeholder - for now
    params.to_unsafe_h.merge(overrides).merge(only_path: false)
  end
end