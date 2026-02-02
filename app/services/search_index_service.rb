# app/services/search_index_service.rb
#
# Manages the Elasticsearch index for parliamentary resources.
# Handles index creation, deletion, and bulk reindexing from SPARQL data.
#
# Usage:
#   SearchIndexService.create_index   # Create index with mappings
#   SearchIndexService.reindex_all    # Reindex all resource types from SPARQL
#   SearchIndexService.delete_index   # Remove the index
#
class SearchIndexService
  INDEX_NAME = 'parliament_resources'.freeze
  BATCH_SIZE = 100

  RESOURCE_TYPES = %i[research_briefing deposited_paper].freeze

  # Mapping from API filter param names to ES keyword field names
  FILTER_PARAMS = {
    'topic' => 'topic_ids',
    'subject' => 'subject_ids',
    'publisher' => 'publisher_ids',
    'section' => 'section_ids',
    'subtype' => 'subtype_ids',
    'category' => 'category_ids',
    'depositing-department' => 'depositing_department_ids',
    'corporate-author' => 'corporate_author_ids',
    'legislature' => 'legislature_ids'
  }.freeze

  def self.create_index
    return if ELASTICSEARCH_CLIENT.indices.exists?(index: INDEX_NAME)

    ELASTICSEARCH_CLIENT.indices.create(
      index: INDEX_NAME,
      body: {
        settings: {
          analysis: {
            analyzer: {
              parliament_analyzer: {
                type: 'custom',
                tokenizer: 'standard',
                filter: %w[lowercase asciifolding english_stemmer]
              }
            },
            filter: {
              english_stemmer: { type: 'stemmer', language: 'english' }
            }
          }
        },
        mappings: {
          properties: {
            resource_type: { type: 'keyword' },
            resource_id:   { type: 'keyword' },
            title:         { type: 'text', analyzer: 'parliament_analyzer' },
            description:   { type: 'text', analyzer: 'parliament_analyzer' },
            identifier:    { type: 'keyword', fields: { text: { type: 'text' } } },
            date:          { type: 'date', format: 'yyyy-MM-dd||strict_date_optional_time||epoch_millis', ignore_malformed: true },
            topics:        { type: 'text', analyzer: 'parliament_analyzer' },
            subjects:      { type: 'text', analyzer: 'parliament_analyzer' },
            publisher:     { type: 'text', analyzer: 'parliament_analyzer' },
            summary:       { type: 'text', analyzer: 'parliament_analyzer' },
            # Keyword fields for taxonomy filtering
            topic_ids:                  { type: 'keyword' },
            subject_ids:                { type: 'keyword' },
            publisher_ids:              { type: 'keyword' },
            section_ids:                { type: 'keyword' },
            subtype_ids:                { type: 'keyword' },
            category_ids:               { type: 'keyword' },
            depositing_department_ids:  { type: 'keyword' },
            corporate_author_ids:       { type: 'keyword' },
            legislature_ids:            { type: 'keyword' }
          }
        }
      }
    )

    Rails.logger.info "[Search] Created index '#{INDEX_NAME}'"
  end

  def self.delete_index
    return unless ELASTICSEARCH_CLIENT.indices.exists?(index: INDEX_NAME)

    ELASTICSEARCH_CLIENT.indices.delete(index: INDEX_NAME)
    Rails.logger.info "[Search] Deleted index '#{INDEX_NAME}'"
  end

  def self.reindex_all
    RESOURCE_TYPES.each { |type| reindex_type(type) }
  end

  def self.reindex_type(type_key)
    offset = 0
    total = 0

    loop do
      result = SparqlGetObject.get_items(
        type_key, '',
        limit: BATCH_SIZE, offset: offset, all_fields: true
      )
      items = result[:items]
      break if items.empty?

      bulk_body = items.flat_map do |item|
        doc = build_document(item, type_key)
        [
          { index: { _index: INDEX_NAME, _id: doc[:doc_id] } },
          doc.except(:doc_id)
        ]
      end

      ELASTICSEARCH_CLIENT.bulk(body: bulk_body)
      total += items.size
      Rails.logger.info "[Search] Indexed #{total} #{type_key} items so far..."

      break if items.size < BATCH_SIZE
      offset += BATCH_SIZE
    end

    Rails.logger.info "[Search] Finished indexing #{total} #{type_key} items"
  end

  def self.build_document(item, type_key)
    formatted = JsonFormatterService.format_item(item)

    title = formatted[:title] || formatted[:abstract]
    description = formatted[:description] || formatted[:abstract]
    date = formatted[:date] || formatted[:dateReceived]

    # Unwrap date if it's a hash with @value
    date = date['@value'] if date.is_a?(Hash) && date['@value']

    {
      doc_id: "#{type_key}_#{item.id}",
      resource_type: type_key.to_s,
      resource_id: item.id.to_s,
      title: title,
      description: description,
      identifier: formatted[:identifier],
      date: date,
      topics: extract_labels(formatted[:topic]),
      subjects: extract_labels(formatted[:subject]),
      publisher: extract_labels(formatted[:publisher]),
      summary: strip_html(formatted[:html_summary]),
      # Term IDs for filtering
      topic_ids: extract_term_ids(formatted[:topic]),
      subject_ids: extract_term_ids(formatted[:subject]),
      publisher_ids: extract_term_ids(formatted[:publisher]),
      section_ids: extract_term_ids(formatted[:section]),
      subtype_ids: extract_term_ids(formatted[:subtype]),
      category_ids: extract_term_ids(formatted[:category]),
      depositing_department_ids: extract_term_ids(formatted[:depositingDepartment]),
      corporate_author_ids: extract_term_ids(formatted[:corporateAuthor]),
      legislature_ids: extract_term_ids(formatted[:legislature])
    }
  end

  private_class_method def self.extract_labels(terms)
    return [] unless terms.is_a?(Array)
    terms.filter_map { |t| t[:label] }
  end

  private_class_method def self.extract_term_ids(terms)
    return [] unless terms.is_a?(Array)
    terms.filter_map { |t| t[:id]&.to_s&.split('/')&.last }
  end

  private_class_method def self.strip_html(html)
    return nil unless html.is_a?(String) && html.present?
    ActionController::Base.helpers.strip_tags(html)
  end
end
