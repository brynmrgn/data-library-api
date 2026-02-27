  # app/models/committee_business.rb
  # AUTO-GENERATED from config/models.yml - Do not edit!
  # Run: rake generate:models

  class CommitteeBusiness < RestApiResource
    BASE_URL = "https://committees-api.parliament.uk".freeze
    API_PATH = "/api/CommitteeBusiness".freeze
    ID_FIELD = "id".freeze

    DEFAULT_SORT_FIELD = :open_date
    DEFAULT_SORT_ORDER = :desc
    SORTABLE_FIELDS = [:open_date, :title].freeze

    ATTRIBUTES = {
  :title => "title",
  :open_date => "openDate",
  :close_date => "closeDate",
  :scope => "scope",
  :latest_report => "latestReport",
  :next_oral_evidence_session => "nextOralEvidenceSession",
  :business_type => {
    :json_key => "type",
    :properties => {
      :id => "id",
      :name => "name",
      :is_inquiry => "isInquiry"
    }
  },
  :contact => {
    :json_key => "contact",
    :properties => {
      :email => "email",
      :phone => "phone",
      :address => "address"
    }
  },
  :open_submission_periods => {
    :json_key => "openSubmissionPeriods",
    :properties => {
      :id => "id",
      :start_date => "startDate",
      :end_date => "endDate",
      :submission_type => "submissionType"
    }
  },
  :closed_submission_periods => {
    :json_key => "closedSubmissionPeriods",
    :properties => {
      :id => "id",
      :start_date => "startDate",
      :end_date => "endDate",
      :submission_type => "submissionType"
    }
  },
  :related_information => {
    :json_key => "relatedInformation",
    :properties => {
      :url => "url",
      :title => "title"
    }
  }
}.freeze

    INDEX_ATTRIBUTES = [:title, :open_date, :close_date, :business_type].freeze
    REQUIRED_ATTRIBUTES = [:title].freeze

    TERM_TYPE_MAPPINGS = {}.freeze

    FILTER_MAPPINGS = {
  :committee_id => {
    :upstream_param => "CommitteeId",
    :label => "committee ID"
  },
  :business_type_id => {
    :upstream_param => "BusinessTypeId",
    :label => "business type ID"
  },
  :status => {
    :upstream_param => "Status",
    :label => "status",
    :values => ["Open", "Closed", "All"]
  },
  :search => {
    :upstream_param => "SearchTerm",
    :label => "search term"
  },
  :date_from => {
    :upstream_param => "DateFrom",
    :label => "start date from"
  },
  :date_to => {
    :upstream_param => "DateTo",
    :label => "start date to"
  }
}.freeze

    def self.construct_uri(id)
      "#{BASE_URL}#{API_PATH}/#{id}"
    end

    finalize_attributes!
  end
