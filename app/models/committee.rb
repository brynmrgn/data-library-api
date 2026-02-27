  # app/models/committee.rb
  # AUTO-GENERATED from config/models.yml - Do not edit!
  # Run: rake generate:models

  class Committee < RestApiResource
    BASE_URL = "https://committees-api.parliament.uk".freeze
    API_PATH = "/api/Committees".freeze
    ID_FIELD = "id".freeze

    DEFAULT_SORT_FIELD = :name
    DEFAULT_SORT_ORDER = :asc
    SORTABLE_FIELDS = [:name, :start_date].freeze

    ATTRIBUTES = {
  :name => "name",
  :house => "house",
  :show_on_website => "showOnWebsite",
  :start_date => "startDate",
  :end_date => "endDate",
  :date_commons_appointed => "dateCommonsAppointed",
  :date_lords_appointed => "dateLordsAppointed",
  :is_lead_committee => "isLeadCommittee",
  :purpose => "purpose",
  :lead_house => "leadHouse",
  :category => {
    :json_key => "category",
    :properties => {
      :id => "id",
      :name => "name"
    }
  },
  :parent_committee => {
    :json_key => "parentCommittee",
    :properties => {
      :id => "id",
      :name => "name"
    }
  },
  :sub_committees => {
    :json_key => "subCommittees",
    :properties => {
      :id => "id",
      :name => "name"
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
  :committee_types => {
    :json_key => "committeeTypes",
    :properties => {
      :id => "id",
      :name => "name"
    }
  },
  :scrutinising_departments => {
    :json_key => "scrutinisingDepartments",
    :properties => {
      :department_id => "departmentId",
      :name => "name"
    }
  },
  :name_history => {
    :json_key => "nameHistory",
    :properties => {
      :id => "id",
      :name => "name",
      :start_date => "startDate",
      :end_date => "endDate"
    }
  },
  :previous_committees => {
    :json_key => "previousCommittees",
    :properties => {
      :id => "id",
      :name => "name"
    }
  },
  :content_links => {
    :json_key => "contentLinks",
    :properties => {
      :url => "url",
      :title => "title"
    }
  }
}.freeze

    INDEX_ATTRIBUTES = [:name, :house, :start_date, :end_date, :category, :committee_types].freeze
    REQUIRED_ATTRIBUTES = [:name].freeze

    TERM_TYPE_MAPPINGS = {}.freeze

    FILTER_MAPPINGS = {
  :house => {
    :upstream_param => "House",
    :label => "house",
    :values => ["Commons", "Lords"]
  },
  :status => {
    :upstream_param => "CommitteeStatus",
    :label => "status",
    :default => "Current",
    :values => ["Current", "All"]
  },
  :category => {
    :upstream_param => "CommitteeCategory",
    :label => "category",
    :values => ["Select", "General", "Other"]
  },
  :search => {
    :upstream_param => "SearchTerm",
    :label => "search term"
  }
}.freeze

    def self.construct_uri(id)
      "#{BASE_URL}#{API_PATH}/#{id}"
    end

    finalize_attributes!
  end
