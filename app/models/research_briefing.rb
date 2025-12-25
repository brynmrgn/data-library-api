# app/models/research_briefing.rb
# AUTO-GENERATED from config/models.yml - Do not edit!
# Run: rake generate:models

class ResearchBriefing < LinkedDataResource
  include SparqlQueryable
  include PresentationHelpers

  SPARQL_TYPE = '<http://data.parliament.uk/schema/parl#ResearchBriefing>'.freeze
  SORT_BY = :date

  ATTRIBUTES = {
  :title => "dc-term:title",
  :identifier => "dc-term:identifier",
  :description => "dc-term:description",
  :date => "dc-term:date",
  :content_location => "parl:contentLocation",
  :external_location => "parl:externalLocation",
  :html_summary => "parl:htmlsummary",
  :topic => {
    :uri => "parl:topic",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :subject => {
    :uri => "dc-term:subject",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :publisher => {
    :uri => "dc-term:publisher",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :section => {
    :uri => "parl:section",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :subtype => {
    :uri => "parl:subtype",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :category => {
    :uri => "parl:category",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :author => {
    :uri => "dc-term:creator",
    :properties => {
      :ses_id => "rdfs:seeAlso",
      :given_name => "schema:givenName",
      :family_name => "schema:familyName"
    }
  },
  :related_link => {
    :uri => "parl:relatedLink",
    :properties => {
      :url => "schema:url",
      :label => "rdfs:label"
    }
  },
  :attachment => {
    :uri => "parl:attachment",
    :properties => {
      :title => "dc-term:title",
      :file_url => "nfo:fileUrl"
    }
  }
}.freeze

  INDEX_ATTRIBUTES = [:title, :identifier, :description, :date, :publisher, :topic].freeze
  REQUIRED_ATTRIBUTES = [:title, :identifier].freeze

  TERM_TYPE_MAPPINGS = {
  "subject" => {
    :predicate => "dc-term:subject",
    :label => "subject"
  },
  "topic" => {
    :predicate => "parl:topic",
    :label => "topic"
  },
  "publisher" => {
    :predicate => "dc-term:publisher",
    :label => "published by"
  },
  "section" => {
    :predicate => "parl:section",
    :label => "Section"
  },
  "subtype" => {
    :predicate => "parl:subtype",
    :label => "Type"
  },
  "category" => {
    :predicate => "parl:category",
    :label => "Category"
  },
  "author" => {
    :predicate => "dc-term:creator",
    :label => "Author",
    :nested => true,
    :nested_predicate => "rdfs:seeAlso"
  }
}.freeze

  LIST_QUERY = <<~SPARQL
    PREFIX parl: <http://data.parliament.uk/schema/parl#>
    PREFIX dc-term: <http://purl.org/dc/terms/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    PREFIX schema: <http://schema.org/>
    PREFIX nfo: <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    CONSTRUCT {
      ?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> ;
        dc-term:title ?title ;
        dc-term:identifier ?identifier ;
        dc-term:description ?description ;
        dc-term:date ?date ;
        dc-term:publisher ?publisher ;
        parl:topic ?topic .
      ?publisher a dc-term:publisher ;
        skos:prefLabel ?publisher_label
     .
      ?topic a parl:topic ;
        skos:prefLabel ?topic_label
     .
    }
    WHERE {
      OPTIONAL { ?item dc-term:title ?title . }
        OPTIONAL { ?item dc-term:identifier ?identifier . }
      OPTIONAL { ?item dc-term:description ?description . }
      OPTIONAL { ?item dc-term:date ?date . }
      OPTIONAL { ?item dc-term:publisher ?publisher .
          ?publisher skos:prefLabel ?publisher_label .
        }
      OPTIONAL { ?item parl:topic ?topic .
          ?topic skos:prefLabel ?topic_label .
        }
    
      {
        SELECT ?item ?sortValue
        WHERE {
          ?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> ;
            dc-term:title ?title ;
              dc-term:identifier ?identifier  ;
            dc-term:date ?sortValue .
          {{FILTER}}
        }
        ORDER BY DESC(?sortValue)
        OFFSET {{OFFSET}}
        LIMIT {{LIMIT}}
      }
    }
  SPARQL

  LIST_QUERY_ALL = <<~SPARQL
    PREFIX parl: <http://data.parliament.uk/schema/parl#>
    PREFIX dc-term: <http://purl.org/dc/terms/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    PREFIX schema: <http://schema.org/>
    PREFIX nfo: <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    CONSTRUCT {
      ?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> ;
        dc-term:title ?title ;
        dc-term:identifier ?identifier ;
        dc-term:description ?description ;
        dc-term:date ?date ;
        parl:contentLocation ?content_location ;
        parl:externalLocation ?external_location ;
        parl:htmlsummary ?html_summary ;
        parl:topic ?topic ;
        dc-term:subject ?subject ;
        dc-term:publisher ?publisher ;
        parl:section ?section ;
        parl:subtype ?subtype ;
        parl:category ?category ;
        dc-term:creator ?author ;
        parl:relatedLink ?related_link ;
        parl:attachment ?attachment .
      ?topic a parl:topic ;
        skos:prefLabel ?topic_label
     .
      ?subject a dc-term:subject ;
        skos:prefLabel ?subject_label
     .
      ?publisher a dc-term:publisher ;
        skos:prefLabel ?publisher_label
     .
      ?section a parl:section ;
        skos:prefLabel ?section_label
     .
      ?subtype a parl:subtype ;
        skos:prefLabel ?subtype_label
     .
      ?category a parl:category ;
        skos:prefLabel ?category_label
     .
      ?author a dc-term:creator ;
        rdfs:seeAlso ?author_ses_id ;
        schema:givenName ?author_given_name ;
        schema:familyName ?author_family_name
     .
      ?related_link a parl:relatedLink ;
        schema:url ?related_link_url ;
        rdfs:label ?related_link_label
     .
      ?attachment a parl:attachment ;
        dc-term:title ?attachment_title ;
        nfo:fileUrl ?attachment_file_url
     .
    }
    WHERE {
      OPTIONAL { ?item dc-term:title ?title . }
        OPTIONAL { ?item dc-term:identifier ?identifier . }
      OPTIONAL { ?item dc-term:description ?description . }
      OPTIONAL { ?item dc-term:date ?date . }
      OPTIONAL { ?item parl:contentLocation ?content_location . }
      OPTIONAL { ?item parl:externalLocation ?external_location . }
      OPTIONAL { ?item parl:htmlsummary ?html_summary . }
      OPTIONAL { ?item parl:topic ?topic .
          ?topic skos:prefLabel ?topic_label .
        }
      OPTIONAL { ?item dc-term:subject ?subject .
          ?subject skos:prefLabel ?subject_label .
        }
      OPTIONAL { ?item dc-term:publisher ?publisher .
          ?publisher skos:prefLabel ?publisher_label .
        }
      OPTIONAL { ?item parl:section ?section .
          ?section skos:prefLabel ?section_label .
        }
      OPTIONAL { ?item parl:subtype ?subtype .
          ?subtype skos:prefLabel ?subtype_label .
        }
      OPTIONAL { ?item parl:category ?category .
          ?category skos:prefLabel ?category_label .
        }
      OPTIONAL { ?item dc-term:creator ?author .
          ?author rdfs:seeAlso ?author_ses_id .
          ?author schema:givenName ?author_given_name .
          ?author schema:familyName ?author_family_name .
        }
      OPTIONAL { ?item parl:relatedLink ?related_link .
          ?related_link schema:url ?related_link_url .
          ?related_link rdfs:label ?related_link_label .
        }
      OPTIONAL { ?item parl:attachment ?attachment .
          ?attachment dc-term:title ?attachment_title .
          ?attachment nfo:fileUrl ?attachment_file_url .
        }
    
      {
        SELECT ?item ?sortValue
        WHERE {
          ?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> ;
            dc-term:title ?title ;
              dc-term:identifier ?identifier  ;
            dc-term:date ?sortValue .
          {{FILTER}}
        }
        ORDER BY DESC(?sortValue)
        OFFSET {{OFFSET}}
        LIMIT {{LIMIT}}
      }
    }
  SPARQL

  SHOW_QUERY = <<~SPARQL
    PREFIX parl: <http://data.parliament.uk/schema/parl#>
    PREFIX dc-term: <http://purl.org/dc/terms/>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    PREFIX schema: <http://schema.org/>
    PREFIX nfo: <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    CONSTRUCT {
      ?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> ;
        dc-term:title ?title ;
        dc-term:identifier ?identifier ;
        dc-term:description ?description ;
        dc-term:date ?date ;
        parl:contentLocation ?content_location ;
        parl:externalLocation ?external_location ;
        parl:htmlsummary ?html_summary ;
        parl:topic ?topic ;
        dc-term:subject ?subject ;
        dc-term:publisher ?publisher ;
        parl:section ?section ;
        parl:subtype ?subtype ;
        parl:category ?category ;
        dc-term:creator ?author ;
        parl:relatedLink ?related_link ;
        parl:attachment ?attachment .
      ?topic a parl:topic ;
        skos:prefLabel ?topic_label
     .
      ?subject a dc-term:subject ;
        skos:prefLabel ?subject_label
     .
      ?publisher a dc-term:publisher ;
        skos:prefLabel ?publisher_label
     .
      ?section a parl:section ;
        skos:prefLabel ?section_label
     .
      ?subtype a parl:subtype ;
        skos:prefLabel ?subtype_label
     .
      ?category a parl:category ;
        skos:prefLabel ?category_label
     .
      ?author a dc-term:creator ;
        rdfs:seeAlso ?author_ses_id ;
        schema:givenName ?author_given_name ;
        schema:familyName ?author_family_name
     .
      ?related_link a parl:relatedLink ;
        schema:url ?related_link_url ;
        rdfs:label ?related_link_label
     .
      ?attachment a parl:attachment ;
        dc-term:title ?attachment_title ;
        nfo:fileUrl ?attachment_file_url
     .
    }
    WHERE {
      ?item a <http://data.parliament.uk/schema/parl#ResearchBriefing> .
      OPTIONAL { ?item dc-term:title ?title . }
        OPTIONAL { ?item dc-term:identifier ?identifier . }
      OPTIONAL { ?item dc-term:description ?description . }
      OPTIONAL { ?item dc-term:date ?date . }
      OPTIONAL { ?item parl:contentLocation ?content_location . }
      OPTIONAL { ?item parl:externalLocation ?external_location . }
      OPTIONAL { ?item parl:htmlsummary ?html_summary . }
      OPTIONAL { ?item parl:topic ?topic .
          ?topic skos:prefLabel ?topic_label .
        }
      OPTIONAL { ?item dc-term:subject ?subject .
          ?subject skos:prefLabel ?subject_label .
        }
      OPTIONAL { ?item dc-term:publisher ?publisher .
          ?publisher skos:prefLabel ?publisher_label .
        }
      OPTIONAL { ?item parl:section ?section .
          ?section skos:prefLabel ?section_label .
        }
      OPTIONAL { ?item parl:subtype ?subtype .
          ?subtype skos:prefLabel ?subtype_label .
        }
      OPTIONAL { ?item parl:category ?category .
          ?category skos:prefLabel ?category_label .
        }
      OPTIONAL { ?item dc-term:creator ?author .
          ?author rdfs:seeAlso ?author_ses_id .
          ?author schema:givenName ?author_given_name .
          ?author schema:familyName ?author_family_name .
        }
      OPTIONAL { ?item parl:relatedLink ?related_link .
          ?related_link schema:url ?related_link_url .
          ?related_link rdfs:label ?related_link_label .
        }
      OPTIONAL { ?item parl:attachment ?attachment .
          ?attachment dc-term:title ?attachment_title .
          ?attachment nfo:fileUrl ?attachment_file_url .
        }
      {{FILTER}}
    }
  SPARQL

  FRAME = {
  "@context" => {
    "parl" => "http://data.parliament.uk/schema/parl#",
    "dc-term" => "http://purl.org/dc/terms/",
    "skos" => "http://www.w3.org/2004/02/skos/core#",
    "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
    "xsd" => "http://www.w3.org/2001/XMLSchema#",
    "schema" => "http://schema.org/",
    "nfo" => "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#",
    "foaf" => "http://xmlns.com/foaf/0.1/"
  },
  "@type" => "http://data.parliament.uk/schema/parl#ResearchBriefing",
  "@embed" => "@always",
  "dc-term:title" => {
    "@embed" => "@always"
  },
  "dc-term:identifier" => {
    "@embed" => "@always"
  },
  "dc-term:description" => {
    "@embed" => "@always"
  },
  "dc-term:date" => {
    "@embed" => "@always"
  },
  "parl:contentLocation" => {
    "@embed" => "@always"
  },
  "parl:externalLocation" => {
    "@embed" => "@always"
  },
  "parl:htmlsummary" => {
    "@embed" => "@always"
  },
  "parl:topic" => {
    "@embed" => "@always"
  },
  "dc-term:subject" => {
    "@embed" => "@always"
  },
  "dc-term:publisher" => {
    "@embed" => "@always"
  },
  "parl:section" => {
    "@embed" => "@always"
  },
  "parl:subtype" => {
    "@embed" => "@always"
  },
  "parl:category" => {
    "@embed" => "@always"
  },
  "dc-term:creator" => {
    "@embed" => "@always"
  },
  "parl:relatedLink" => {
    "@embed" => "@always"
  },
  "parl:attachment" => {
    "@embed" => "@always"
  }
}.freeze

  def self.construct_uri(id)
    "http://data.parliament.uk/resources/#{id}"
  end

  finalize_attributes!
end
