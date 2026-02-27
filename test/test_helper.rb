ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # COMMENT OUT fixtures since we don't use a database
    # fixtures :all

    # Mock SPARQL responses
    def mock_sparql_response(body)
      response = Minitest::Mock.new
      response.expect :body, body.to_json
      response
    end
    
    def mock_term_sparql(term_id, pref_label, first_name = nil, surname = nil)
      bindings = [{
        "termLabel" => {"type" => "literal", "value" => pref_label}
      }]
      
      bindings[0]["firstName"] = {"type" => "literal", "value" => first_name} if first_name
      bindings[0]["surname"] = {"type" => "literal", "value" => surname} if surname
      
      {
        "head" => {"vars" => ["termLabel", "firstName", "surname"]},
        "results" => {"bindings" => bindings}
      }
    end
    
    def sample_research_briefing_data
      {
        "@id" => "http://data.parliament.uk/resources/344893",
        "dc-term:title" => "Apprenticeship statistics (England)",
        "dc-term:date" => "2024-12-06",
        "dc-term:abstract" => "Statistics on apprenticeships in England",
        "dc-term:created" => "2015-03-25T11:24:24+00:00",
        "dc-term:modified" => "2024-12-06T10:28:10+00:00",
        "parl:published" => "true",
        "parl:status" => "published",
        "ov:disclaimer" => "&lt;p&gt;This information is provided to Members of Parliament.&lt;/p&gt;",
        "parl:internalLocation" => {"@id" => "http://researchbriefingsintranet.parliament.uk/ResearchBriefing/Summary/SN06113"},
        "parl:relatedLink" => [
          {
            "@id" => "http://data.parliament.uk/resources/344893/relatedlinks/1",
            "schema:url" => {"@id" => "http://example.com/link1"},
            "rdfs:label" => "Link 1"
          },
          {
            "@id" => "http://data.parliament.uk/resources/344893/relatedlinks/2",
            "schema:url" => {"@id" => "http://example.com/link2"},
            "rdfs:label" => "Link 2"
          }
        ],
        "dc-term:creator" => {
          "@id" => "http://data.parliament.uk/resources/344893/authors/1",
          "rdfs:seeAlso" => {"@id" => "http://data.parliament.uk/terms/395733"},
          "schema:givenName" => "Matthew",
          "schema:familyName" => "Ward"
        },
        "dc-term:subject" => [
          {"@id" => "http://data.parliament.uk/terms/90236", "skos:prefLabel" => "Apprentices"},
          {"@id" => "http://data.parliament.uk/terms/93316", "skos:prefLabel" => "Training"}
        ]
      }
    end
    
    def sample_deposited_paper_data
      {
        "@id" => "http://data.parliament.uk/resources/340587",
        "dc-term:identifier" => "DEP2024-0001",
        "parl:dateReceived" => "2024-01-15",
        "parl:relatedLink" => [
          {
            "@id" => "http://data.parliament.uk/resources/340587/relatedlinks/1",
            "schema:url" => {"@id" => "http://example.com/paper-link"},
            "rdfs:label" => "Related Document"
          }
        ]
      }
    end
  end
end