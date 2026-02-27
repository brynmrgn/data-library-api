  # app/models/event.rb
  # AUTO-GENERATED from config/models.yml - Do not edit!
  # Run: rake generate:models

  class Event < RestApiResource
    BASE_URL = "https://committees-api.parliament.uk".freeze
    API_PATH = "/api/Events".freeze
    ID_FIELD = "id".freeze

    DEFAULT_SORT_FIELD = :start_date
    DEFAULT_SORT_ORDER = :desc
    SORTABLE_FIELDS = [:start_date, :name].freeze

    ATTRIBUTES = {
  :name => "name",
  :start_date => "startDate",
  :end_date => "endDate",
  :cancelled_date => "cancelledDate",
  :location => "location",
  :event_source => "eventSource",
  :primary_description => "primaryDescription",
  :secondary_description => "secondaryDescription",
  :parliament_tv_url => "parliamentTvUrl",
  :event_type => {
    :json_key => "eventType",
    :properties => {
      :id => "id",
      :name => "name",
      :is_visit => "isVisit"
    }
  },
  :committees => {
    :json_key => "committees",
    :properties => {
      :id => "id",
      :name => "name",
      :house => "house"
    }
  },
  :committee_businesses => {
    :json_key => "committeeBusinesses",
    :properties => {
      :id => "id",
      :title => "title"
    }
  },
  :activities => {
    :json_key => "activities",
    :properties => {
      :id => "id",
      :name => "name",
      :start_date => "startDate",
      :end_date => "endDate",
      :activity_type => "activityType",
      :is_private => "isPrivate"
    }
  }
}.freeze

    INDEX_ATTRIBUTES = [:name, :start_date, :end_date, :location, :event_type, :committees].freeze
    REQUIRED_ATTRIBUTES = [:name].freeze

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
  :house => {
    :upstream_param => "House",
    :label => "house",
    :values => ["Commons", "Lords"]
  },
  :start_date_from => {
    :upstream_param => "StartDateFrom",
    :label => "start date from"
  },
  :start_date_to => {
    :upstream_param => "StartDateTo",
    :label => "start date to"
  },
  :search => {
    :upstream_param => "SearchTerm",
    :label => "search term"
  },
  :event_type_id => {
    :upstream_param => "EventTypeId",
    :label => "event type ID"
  },
  :exclude_cancelled => {
    :upstream_param => "ExcludeCancelledEvents",
    :label => "exclude cancelled events",
    :values => ["true", "false"]
  }
}.freeze

    def self.construct_uri(id)
      "#{BASE_URL}#{API_PATH}/#{id}"
    end

    finalize_attributes!
  end
