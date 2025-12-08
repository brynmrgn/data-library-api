# app/services/sparql_query_service.rb
class SparqlQueryService
  def self.build_query(type_key, filter, limit, offset)
    model_class = get_model_class(type_key)
    query_module = model_class::QUERY_MODULE.constantize
    query_module.list_query(filter, offset: offset, limit: limit)
  end

  private

  def self.build_query(model_class, filter, limit, offset)
    query_module = model_class::QUERY_MODULE
    query_module.list_query(filter, offset: offset, limit: limit)
  end
end