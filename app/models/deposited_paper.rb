# app/models/deposited_paper.rb
# AUTO-GENERATED from config/models.yml - Do not edit!
# Run: rake generate:models

class DepositedPaper < LinkedDataResource

  SPARQL_TYPE = '<http://data.parliament.uk/schema/parl#DepositedPaper>'.freeze
  SORT_BY = :dateReceived

  ATTRIBUTES = {
  :title => "dc-term:title",
  :identifier => "dc-term:identifier",
  :abstract => "dc-term:abstract",
  :dateReceived => "parl:dateReceived",
  :lastModified => "parl:dateLastModified",
  :dateOfOrigin => "parl:dateOfOrigin",
  :dateOfCommitmentToDeposit => "parl:dateOfCommitmentToDeposit",
  :depositedFile => "parl:depositedFile",
  :indexingStatus => "parl:indexStatus",
  :corporateAuthor => {
    :uri => "parl:corporateAuthor",
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
  :depositingDepartment => {
    :uri => "parl:department",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :legislature => {
    :uri => "parl:legislature",
    :properties => {
      :label => "skos:prefLabel"
    }
  },
  :relation => {
    :uri => "dc-term:relation",
    :properties => {
      :externalLocation => "parl:externalLocation",
      :title => "dc-term:title"
    }
  }
}.freeze

  INDEX_ATTRIBUTES = [:abstract, :identifier, :depositingDepartment, :dateReceived, :legislature].freeze
  REQUIRED_ATTRIBUTES = [:abstract, :identifier, :dateReceived].freeze

  TERM_TYPE_MAPPINGS = {
  "subject" => {
    :predicate => "dc-term:subject",
    :label => "subject"
  },
  "publisher" => {
    :predicate => "dc-term:publisher",
    :label => "published by"
  },
  "depositing-department" => {
    :predicate => "parl:department",
    :label => "deposited by"
  },
  "corporate-author" => {
    :predicate => "parl:corporateAuthor",
    :label => "author"
  },
  "legislature" => {
    :predicate => "parl:legislature",
    :label => "house"
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
      ?item a <http://data.parliament.uk/schema/parl#DepositedPaper> ;
        dc-term:abstract ?abstract ;
        dc-term:identifier ?identifier ;
        parl:department ?depositingDepartment ;
        parl:dateReceived ?dateReceived ;
        parl:legislature ?legislature .
      ?depositingDepartment a parl:department ;
        skos:prefLabel ?depositingDepartment_label
     .
      ?legislature a parl:legislature ;
        skos:prefLabel ?legislature_label
     .
    }
    WHERE {
      OPTIONAL { ?item dc-term:abstract ?abstract . }
        OPTIONAL { ?item dc-term:identifier ?identifier . }
        OPTIONAL { ?item parl:dateReceived ?dateReceived . }
      OPTIONAL { ?item parl:department ?depositingDepartment .
          ?depositingDepartment skos:prefLabel ?depositingDepartment_label .
        }
      OPTIONAL { ?item parl:legislature ?legislature .
          ?legislature skos:prefLabel ?legislature_label .
        }
    
      {
        SELECT ?item ?sortValue
        WHERE {
          ?item a <http://data.parliament.uk/schema/parl#DepositedPaper> ;
            dc-term:abstract ?abstract ;
              dc-term:identifier ?identifier ;
              parl:dateReceived ?dateReceived  ;
            parl:dateReceived ?sortValue .
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
      ?item a <http://data.parliament.uk/schema/parl#DepositedPaper> ;
        dc-term:title ?title ;
        dc-term:identifier ?identifier ;
        dc-term:abstract ?abstract ;
        parl:dateReceived ?dateReceived ;
        parl:dateLastModified ?lastModified ;
        parl:dateOfOrigin ?dateOfOrigin ;
        parl:dateOfCommitmentToDeposit ?dateOfCommitmentToDeposit ;
        parl:depositedFile ?depositedFile ;
        parl:indexStatus ?indexingStatus ;
        parl:corporateAuthor ?corporateAuthor ;
        dc-term:subject ?subject ;
        parl:department ?depositingDepartment ;
        parl:legislature ?legislature ;
        dc-term:relation ?relation .
      ?corporateAuthor a parl:corporateAuthor ;
        skos:prefLabel ?corporateAuthor_label
     .
      ?subject a dc-term:subject ;
        skos:prefLabel ?subject_label
     .
      ?depositingDepartment a parl:department ;
        skos:prefLabel ?depositingDepartment_label
     .
      ?legislature a parl:legislature ;
        skos:prefLabel ?legislature_label
     .
      ?relation a dc-term:relation ;
        parl:externalLocation ?relation_externalLocation ;
        dc-term:title ?relation_title
     .
    }
    WHERE {
      OPTIONAL { ?item dc-term:abstract ?abstract . }
        OPTIONAL { ?item dc-term:identifier ?identifier . }
        OPTIONAL { ?item parl:dateReceived ?dateReceived . }
      OPTIONAL { ?item dc-term:title ?title . }
      OPTIONAL { ?item parl:dateLastModified ?lastModified . }
      OPTIONAL { ?item parl:dateOfOrigin ?dateOfOrigin . }
      OPTIONAL { ?item parl:dateOfCommitmentToDeposit ?dateOfCommitmentToDeposit . }
      OPTIONAL { ?item parl:depositedFile ?depositedFile . }
      OPTIONAL { ?item parl:indexStatus ?indexingStatus . }
      OPTIONAL { ?item parl:corporateAuthor ?corporateAuthor .
          ?corporateAuthor skos:prefLabel ?corporateAuthor_label .
        }
      OPTIONAL { ?item dc-term:subject ?subject .
          ?subject skos:prefLabel ?subject_label .
        }
      OPTIONAL { ?item parl:department ?depositingDepartment .
          ?depositingDepartment skos:prefLabel ?depositingDepartment_label .
        }
      OPTIONAL { ?item parl:legislature ?legislature .
          ?legislature skos:prefLabel ?legislature_label .
        }
      OPTIONAL { ?item dc-term:relation ?relation .
          ?relation parl:externalLocation ?relation_externalLocation .
          ?relation dc-term:title ?relation_title .
        }
    
      {
        SELECT ?item ?sortValue
        WHERE {
          ?item a <http://data.parliament.uk/schema/parl#DepositedPaper> ;
            dc-term:abstract ?abstract ;
              dc-term:identifier ?identifier ;
              parl:dateReceived ?dateReceived  ;
            parl:dateReceived ?sortValue .
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
      ?item a <http://data.parliament.uk/schema/parl#DepositedPaper> ;
        dc-term:title ?title ;
        dc-term:identifier ?identifier ;
        dc-term:abstract ?abstract ;
        parl:dateReceived ?dateReceived ;
        parl:dateLastModified ?lastModified ;
        parl:dateOfOrigin ?dateOfOrigin ;
        parl:dateOfCommitmentToDeposit ?dateOfCommitmentToDeposit ;
        parl:depositedFile ?depositedFile ;
        parl:indexStatus ?indexingStatus ;
        parl:corporateAuthor ?corporateAuthor ;
        dc-term:subject ?subject ;
        parl:department ?depositingDepartment ;
        parl:legislature ?legislature ;
        dc-term:relation ?relation .
      ?corporateAuthor a parl:corporateAuthor ;
        skos:prefLabel ?corporateAuthor_label
     .
      ?subject a dc-term:subject ;
        skos:prefLabel ?subject_label
     .
      ?depositingDepartment a parl:department ;
        skos:prefLabel ?depositingDepartment_label
     .
      ?legislature a parl:legislature ;
        skos:prefLabel ?legislature_label
     .
      ?relation a dc-term:relation ;
        parl:externalLocation ?relation_externalLocation ;
        dc-term:title ?relation_title
     .
    }
    WHERE {
      ?item a <http://data.parliament.uk/schema/parl#DepositedPaper> .
      OPTIONAL { ?item dc-term:abstract ?abstract . }
        OPTIONAL { ?item dc-term:identifier ?identifier . }
        OPTIONAL { ?item parl:dateReceived ?dateReceived . }
      OPTIONAL { ?item dc-term:title ?title . }
      OPTIONAL { ?item parl:dateLastModified ?lastModified . }
      OPTIONAL { ?item parl:dateOfOrigin ?dateOfOrigin . }
      OPTIONAL { ?item parl:dateOfCommitmentToDeposit ?dateOfCommitmentToDeposit . }
      OPTIONAL { ?item parl:depositedFile ?depositedFile . }
      OPTIONAL { ?item parl:indexStatus ?indexingStatus . }
      OPTIONAL { ?item parl:corporateAuthor ?corporateAuthor .
          ?corporateAuthor skos:prefLabel ?corporateAuthor_label .
        }
      OPTIONAL { ?item dc-term:subject ?subject .
          ?subject skos:prefLabel ?subject_label .
        }
      OPTIONAL { ?item parl:department ?depositingDepartment .
          ?depositingDepartment skos:prefLabel ?depositingDepartment_label .
        }
      OPTIONAL { ?item parl:legislature ?legislature .
          ?legislature skos:prefLabel ?legislature_label .
        }
      OPTIONAL { ?item dc-term:relation ?relation .
          ?relation parl:externalLocation ?relation_externalLocation .
          ?relation dc-term:title ?relation_title .
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
  "@type" => "http://data.parliament.uk/schema/parl#DepositedPaper",
  "@embed" => "@always",
  "dc-term:title" => {
    "@embed" => "@always"
  },
  "dc-term:identifier" => {
    "@embed" => "@always"
  },
  "dc-term:abstract" => {
    "@embed" => "@always"
  },
  "parl:dateReceived" => {
    "@embed" => "@always"
  },
  "parl:dateLastModified" => {
    "@embed" => "@always"
  },
  "parl:dateOfOrigin" => {
    "@embed" => "@always"
  },
  "parl:dateOfCommitmentToDeposit" => {
    "@embed" => "@always"
  },
  "parl:depositedFile" => {
    "@embed" => "@always"
  },
  "parl:indexStatus" => {
    "@embed" => "@always"
  },
  "parl:corporateAuthor" => {
    "@embed" => "@always"
  },
  "dc-term:subject" => {
    "@embed" => "@always"
  },
  "parl:department" => {
    "@embed" => "@always"
  },
  "parl:legislature" => {
    "@embed" => "@always"
  },
  "dc-term:relation" => {
    "@embed" => "@always"
  }
}.freeze

  def self.construct_uri(id)
    "http://data.parliament.uk/depositedpapers/#{id}"
  end

  finalize_attributes!
end
