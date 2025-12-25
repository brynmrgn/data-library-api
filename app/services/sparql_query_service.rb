# app/services/sparql_query_service.rb
class SparqlQueryService
  def self.build_query(model_class, filter, limit, offset, all_fields: false)
    query = SparqlQueryBuilder.list_query(model_class, filter, offset: offset, limit: limit, all_fields: all_fields)
    Rails.logger.info("=" * 80)
    Rails.logger.info("GENERATED SPARQL QUERY:")
    Rails.logger.info(query)
    Rails.logger.info("=" * 80)
    query
  end
end
