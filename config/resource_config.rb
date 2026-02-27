# config/resource_config.rb
# AUTO-GENERATED from config/models.yml - Do not edit!
# Run: rake generate:models

RESOURCE_CONFIG = {
  "research-briefings" => {
    :controller_name => "research_briefings",
    :model_class => "ResearchBriefing",
    :source => "sparql"
  },
  "deposited-papers" => {
    :controller_name => "deposited_papers",
    :model_class => "DepositedPaper",
    :source => "sparql"
  },
  "committees" => {
    :controller_name => "committees",
    :model_class => "Committee",
    :source => "rest"
  },
  "committee-business" => {
    :controller_name => "committee_businesses",
    :model_class => "CommitteeBusiness",
    :source => "rest"
  },
  "events" => {
    :controller_name => "events",
    :model_class => "Event",
    :source => "rest"
  },
  "bill-petitions" => {
    :controller_name => "bill_petitions",
    :model_class => "BillPetition",
    :source => "rest"
  },
  "oral-evidence" => {
    :controller_name => "oral_evidences",
    :model_class => "OralEvidence",
    :source => "rest"
  },
  "written-evidence" => {
    :controller_name => "written_evidences",
    :model_class => "WrittenEvidence",
    :source => "rest"
  },
  "committee-business-types" => {
    :controller_name => "committee_business_types",
    :model_class => "CommitteeBusinessType",
    :source => "rest"
  },
  "committee-types" => {
    :controller_name => "committee_types",
    :model_class => "CommitteeType",
    :source => "rest"
  },
  "countries" => {
    :controller_name => "countries",
    :model_class => "Country",
    :source => "rest"
  }
}.freeze
