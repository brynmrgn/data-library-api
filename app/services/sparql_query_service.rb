# app/services/sparql_query_service.rb
class SparqlQueryService
  def self.build_query(model_class, filter, limit, offset)
    query_module = model_class::QUERY_MODULE
    query = query_module.list_query(model_class, filter, offset: offset, limit: limit)
    Rails.logger.info("=" * 80)
    Rails.logger.info("GENERATED SPARQL QUERY:")
    Rails.logger.info(query)
    Rails.logger.info("=" * 80)
    query
  end
end

