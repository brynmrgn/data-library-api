module Sparql::Queries::DepositedPapers

    # A Sparql query to get deposited papers - in date order
	def list_query(filter, offset:, limit:)
        "
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX rdfs:<http://www.w3.org/2000/01/rdf-schema#>
PREFIX dc-term:<http://purl.org/dc/terms/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

construct { 
	?item a <http://data.parliament.uk/schema/parl#DepositedPaper>; 
		dc-term:title ?title ;
		dc-term:identifier ?identifier;
		dc-term:abstract ?abstract;
		<http://data.parliament.uk/schema/parl#dateReceived> ?date ;
		<http://data.parliament.uk/schema/parl#corporateAuthor> ?corporateAuthor ;
		dc-term:subject ?subject ;
		<http://data.parliament.uk/schema/parl#department> ?depositingDepartment ;
		<http://data.parliament.uk/schema/parl#depositedFile> ?depositedFile ;
		<http://data.parliament.uk/schema/parl#indexStatus> ?indexingStatus ;
		<http://data.parliament.uk/schema/parl#legislature> ?legislature .
	?depositingDepartment a <http://data.parliament.uk/schema/parl#department> ;
		skos:prefLabel ?depositingDepartmentLabel .
	?subject a dc-term:subject ;
		skos:prefLabel ?subjectLabel .
  	?corporateAuthor a <http://data.parliament.uk/schema/parl#corporateAuthor> ;
    	skos:prefLabel ?corporateAuthorLabel .
	?legislature a <http://data.parliament.uk/schema/parl#legislature> ;
      	skos:prefLabel ?legislatureLabel .
} 
where {
	?item dc-term:title ?title ;
		dc-term:identifier ?identifier;
		<http://data.parliament.uk/schema/parl#dateReceived> ?date .
	OPTIONAL {?item <http://data.parliament.uk/schema/parl#corporateAuthor> ?corporateAuthor .
    	?corporateAuthor skos:prefLabel ?corporateAuthorLabel .}
	OPTIONAL {?item <http://data.parliament.uk/schema/parl#legislature> ?legislature .
        ?legislature skos:prefLabel ?legislatureLabel .}
	?item dc-term:abstract ?abstract .
	OPTIONAL {?item dc-term:subject ?subject .
  		?subject skos:prefLabel ?subjectLabel}
	OPTIONAL {?item <http://data.parliament.uk/schema/parl#department> ?depositingDepartment .
		?depositingDepartment skos:prefLabel ?depositingDepartmentLabel .}
	OPTIONAL {?item <http://data.parliament.uk/schema/parl#indexStatus> ?indexingStatus .}
	OPTIONAL {?item <http://data.parliament.uk/schema/parl#depositedFile> ?depositedFile .}
  	{select ?item
		WHERE { 
    		?item a <http://data.parliament.uk/schema/parl#DepositedPaper> . 
    		?item	<http://data.parliament.uk/schema/parl#dateReceived> ?date .
			#{filter}
			} 
    	ORDER BY DESC(?date) 
    	OFFSET #{Integer(offset)}
    	LIMIT #{Integer(limit)}
  		}
}
"
	end

	def item_frame
		'''
		{"@context": {
    		"item": "http://data.parliament.uk/schema/parl#DepositedPaper"
  			},
 		"http://data.parliament.uk/schema/parl#department": {"@embed": "@always"},
  		"http://purl.org/dc/terms/subject": {"@embed": "@always"},
  		"http://data.parliament.uk/schema/parl#corporateAuthor": {"@embed": "@always", "@container": "@set"},
		"http://data.parliament.uk/schema/parl#legislature": {"@embed": "@always"}
		}
		'''
	end 
end