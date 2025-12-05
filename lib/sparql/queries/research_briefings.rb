module Sparql::Queries::ResearchBriefings

    # A Sparql query to get deposited papers - in date order
	def list_query(filter, offset:, limit:)
        "
PREFIX skos:<http://www.w3.org/2004/02/skos/core#>
PREFIX rdfs:<http://www.w3.org/2000/01/rdf-schema#>
PREFIX dc-term:<http://purl.org/dc/terms/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

construct { 
	?item a <http://data.parliament.uk/schema/parl#ResearchBriefing>; 
		dc-term:title ?title ;
		dc-term:identifier ?identifier;
		dc-term:description ?description;
    	dc-term:date ?date ;
		<http://data.parliament.uk/schema/parl#topic> ?topic ;
    	dc-term:subject ?subject ;
        dc-term:publisher ?publisher ;
    	dc-term:creator ?author ;
    	<http://data.parliament.uk/schema/parl#subtype> ?subType ;
    	<http://data.parliament.uk/schema/parl#section> ?section ;
    	<http://data.parliament.uk/schema/parl#category> ?category ;
  		<http://data.parliament.uk/schema/parl#contentLocation> ?pdfLocation ;
    	<http://data.parliament.uk/schema/parl#externalLocation> ?externalLocation ;
        <http://data.parliament.uk/schema/parl#relatedLink> ?relatedLink ;
        <http://data.parliament.uk/schema/parl#attachment> ?attachment ;
  		<http://data.parliament.uk/schema/parl#htmlsummary> ?htmlSummary .
  		 
	?topic a <http://data.parliament.uk/schema/parl#topic> ;
		skos:prefLabel ?topicLabel .
    ?subject a dc-term:subject ;
  		skos:prefLabel ?subjectLabel .
    ?publisher a dc-term:publisher ;
    	skos:prefLabel ?publisherLabel .
  	?section a <http://data.parliament.uk/schema/parl#section> ;
    	skos:prefLabel ?sectionLabel .
  	?subType a <http://data.parliament.uk/schema/parl#subtype> ;
    	skos:prefLabel ?subTypeLabel .
  	?category a <http://data.parliament.uk/schema/parl#category> ;
    	skos:prefLabel ?categoryLabel .
  	?author a dc-term:creator ;
    	rdfs:seeAlso ?authorSesId ;
    	<http://schema.org/givenName> ?givenName ;
  		<http://schema.org/familyName> ?familyName .
    ?relatedLink a <http://data.parliament.uk/schema/parl#relatedLink> ;
    	<http://schema.org/url> ?url ;
  		<http://www.w3.org/2000/01/rdf-schema#label> ?label .
    ?attachment a <http://data.parliament.uk/schema/parl#attachment> ;
    	dc-term:title ?attachmentTitle ;
    	<http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileUrl> ?fileUrl .
}
where {
	?item dc-term:title ?title ;
		dc-term:identifier ?identifier;
	OPTIONAL {?item dc-term:description ?description .}
	OPTIONAL {?item <http://data.parliament.uk/schema/parl#topic> ?topic .
  		?topic skos:prefLabel ?topicLabel}
   	OPTIONAL {?item dc-term:subject ?subject .
  		?subject skos:prefLabel ?subjectLabel}
    OPTIONAL {?item dc-term:publisher ?publisher .
  		?publisher skos:prefLabel ?publisherLabel}
    OPTIONAL {?item <http://data.parliament.uk/schema/parl#section> ?section .
        ?section skos:prefLabel ?sectionLabel}
    OPTIONAL {?item <http://data.parliament.uk/schema/parl#subtype> ?subType .
        ?subType skos:prefLabel ?subTypeLabel}  
    OPTIONAL {?item <http://data.parliament.uk/schema/parl#category> ?category .
        ?category skos:prefLabel ?categoryLabel}
    OPTIONAL {?item dc-term:creator ?author .
        ?author rdfs:seeAlso ?authorSesId ;
        <http://schema.org/givenName> ?givenName ;
  		<http://schema.org/familyName> ?familyName . }  
  	OPTIONAL {?item <http://data.parliament.uk/schema/parl#relatedLink> ?relatedLink .
  		?relatedLink <http://schema.org/url> ?url ;
  		<http://www.w3.org/2000/01/rdf-schema#label> ?label . }
   	OPTIONAL {?item <http://data.parliament.uk/schema/parl#attachment> ?attachment .
    	?attachment dc-term:title ?attachmentTitle ;
    	<http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#fileUrl> ?fileUrl . } 	
    OPTIONAL {?item <http://data.parliament.uk/schema/parl#contentLocation> ?pdfLocation .}
    OPTIONAL {?item <http://data.parliament.uk/schema/parl#externalLocation> ?externalLocation .}
    OPTIONAL {?item <http://data.parliament.uk/schema/parl#htmlsummary> ?htmlSummary .}

  	{select ?item ?date
		WHERE { 
    		?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> ;
  			 dc-term:date ?date .
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
    		"item": "http://data.parliament.uk/schema/parl#ResearchBriefing"
  			},
		"http://data.parliament.uk/schema/parl#topic": {"@embed": "@always"},
		"http://purl.org/dc/terms/subject": {"@embed": "@always"},
		"http://purl.org/dc/terms/publisher": {"@embed": "@always"},
		"http://data.parliament.uk/schema/parl#section": {"@embed": "@always"},
		"http://data.parliament.uk/schema/parl#subtype": {"@embed": "@always"},
		"http://data.parliament.uk/schema/parl#category": {"@embed": "@always"},
		"http://purl.org/dc/terms/creator": {"@embed": "@always"},
		"http://data.parliament.uk/schema/parl#relatedLink": {"@embed": "@always"},
		"http://data.parliament.uk/schema/parl#attachment": {"@embed": "@always"}
		}
		'''
	end 

end