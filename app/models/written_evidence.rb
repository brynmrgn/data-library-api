  # app/models/written_evidence.rb
  # AUTO-GENERATED from config/models.yml - Do not edit!
  # Run: rake generate:models

  class WrittenEvidence < RestApiResource
    BASE_URL = "https://committees-api.parliament.uk".freeze
    API_PATH = "/api/WrittenEvidence".freeze
    ID_FIELD = "id".freeze

    DEFAULT_SORT_FIELD = :publication_date
    DEFAULT_SORT_ORDER = :desc
    SORTABLE_FIELDS = [:publication_date].freeze

    ATTRIBUTES = {
  :submission_id => "submissionId",
  :internal_reference => "internalReference",
  :publication_date => "publicationDate",
  :anonymous => "anonymous",
  :anonymous_witness_text => "anonymousWitnessText",
  :legacy_html_url => "legacyHtmlUrl",
  :legacy_pdf_url => "legacyPdfUrl",
  :hc_number => {
    :json_key => "hcNumber",
    :properties => {
      :number => "number",
      :session_id => "sessionId",
      :session_description => "sessionDescription"
    }
  },
  :committee_business => {
    :json_key => "committeeBusiness",
    :properties => {
      :id => "id",
      :title => "title"
    }
  },
  :witnesses => {
    :json_key => "witnesses",
    :properties => {
      :id => "id",
      :name => "name",
      :submitter_type => "submitterType"
    }
  },
  :document => {
    :json_key => "document",
    :properties => {
      :document_id => "documentId"
    }
  },
  :committees => {
    :json_key => "committees",
    :properties => {
      :id => "id",
      :name => "name",
      :house => "house"
    }
  }
}.freeze

    INDEX_ATTRIBUTES = [:publication_date, :committee_business, :committees, :witnesses].freeze
    REQUIRED_ATTRIBUTES = [:publication_date].freeze

    TERM_TYPE_MAPPINGS = {}.freeze

    FILTER_MAPPINGS = {
  :committee_id => {
    :upstream_param => "CommitteeId",
    :label => "committee ID"
  },
  :committee_business_id => {
    :upstream_param => "CommitteeBusinessId",
    :label => "committee business ID"
  },
  :search => {
    :upstream_param => "SearchTerm",
    :label => "search term"
  },
  :start_date => {
    :upstream_param => "StartDate",
    :label => "start date"
  },
  :end_date => {
    :upstream_param => "EndDate",
    :label => "end date"
  }
}.freeze

    def self.construct_uri(id)
      "#{BASE_URL}#{API_PATH}/#{id}"
    end

    finalize_attributes!
  end
