# app/models/term.rb
#
# Model for parliamentary thesaurus terms (SES concepts)
# Unlike other resources, terms use simple SELECT queries rather than CONSTRUCT/framing
#
class Term
  BASE_URI = 'http://data.parliament.uk/terms/'.freeze
  URI_PATTERN = "^#{BASE_URI}[0-9]+$".freeze

  # Index query - list all terms with SES IDs
  INDEX_QUERY = <<~SPARQL.freeze
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>

    SELECT DISTINCT ?term ?prefLabel ?firstName ?surname
    WHERE {
      ?term a skos:Concept .
      FILTER(REGEX(STR(?term), "#{URI_PATTERN}"))
      OPTIONAL { ?term skos:prefLabel ?prefLabel . }
      OPTIONAL { ?term foaf:firstName ?firstName . }
      OPTIONAL { ?term foaf:surname ?surname . }
    }
    ORDER BY ?prefLabel ?surname
    LIMIT {{LIMIT}}
    OFFSET {{OFFSET}}
  SPARQL

  # Count query for pagination
  COUNT_QUERY = <<~SPARQL.freeze
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

    SELECT (COUNT(DISTINCT ?term) as ?count)
    WHERE {
      ?term a skos:Concept .
      FILTER(REGEX(STR(?term), "#{URI_PATTERN}"))
    }
  SPARQL

  # Show query - get all triples for a term
  SHOW_QUERY = <<~SPARQL.freeze
    SELECT ?predicate ?object
    WHERE {
      <{{TERM_URI}}> ?predicate ?object .
    }
    LIMIT 100
  SPARQL

  # SKOS and FOAF predicates
  PREDICATES = {
    pref_label: 'http://www.w3.org/2004/02/skos/core#prefLabel',
    alt_label: 'http://www.w3.org/2004/02/skos/core#altLabel',
    broader: 'http://www.w3.org/2004/02/skos/core#broader',
    narrower: 'http://www.w3.org/2004/02/skos/core#narrower',
    first_name: 'http://xmlns.com/foaf/0.1/firstName',
    family_name: 'http://xmlns.com/foaf/0.1/surname',
    uncontrolled: 'http://data.parliament.uk/schema/parl#uncontrolledName'
  }.freeze

  attr_reader :id, :uri, :data

  def initialize(id:, data:)
    @id = id
    @uri = "#{BASE_URI}#{id}"
    @data = data
  end

  def pref_label
    data[PREDICATES[:pref_label]]
  end

  def alt_label
    data[PREDICATES[:alt_label]]
  end

  def broader
    data[PREDICATES[:broader]]
  end

  def narrower
    data[PREDICATES[:narrower]]
  end

  def first_name
    data[PREDICATES[:first_name]]
  end

  def family_name
    data[PREDICATES[:family_name]]
  end

  def uncontrolled
    data[PREDICATES[:uncontrolled]]
  end

  def label
    # Try foaf:firstName + foaf:surname first (for authors)
    if first_name && family_name
      "#{first_name} #{family_name}"
    elsif pref_label
      # If it looks like "Surname, Firstname", reverse it
      if pref_label =~ /^(.+),\s*(.+)$/
        "#{$2} #{$1}"
      else
        pref_label
      end
    end
  end

  def to_h
    {
      id: id,
      uri: uri,
      pref_label: pref_label,
      alt_label: alt_label,
      first_name: first_name,
      family_name: family_name,
      uncontrolled: uncontrolled,
      broader: broader,
      narrower: narrower,
      data: data
    }.compact
  end

  def self.construct_uri(id)
    "#{BASE_URI}#{id}"
  end

  def self.index_query(limit:, offset:)
    INDEX_QUERY.gsub('{{LIMIT}}', limit.to_s).gsub('{{OFFSET}}', offset.to_s)
  end

  def self.show_query(id)
    SHOW_QUERY.gsub('{{TERM_URI}}', construct_uri(id))
  end
end
