module SparqlQueryable
  extend ActiveSupport::Concern
  
  class_methods do
    def list_query(filter, offset:, limit:)
      SparqlQueryBuilder.list_query(self, filter, offset: offset, limit: limit)
    end
    
    def show_query(uri)
      SparqlQueryBuilder.show_query(self, uri)
    end
  end
end