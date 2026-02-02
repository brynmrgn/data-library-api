# API Format Comparison

Comparison between the existing Linked Data API (LDA) and the Data Library API for the same resources (e.g. research briefings).

## Item Structure

| Aspect | Existing LDA | Data Library API |
|--------|-------------|------------------|
| Resource identifier | `_about` (full URI) | `id` (short ID) and `uri` (full URI) |
| Simple values | Wrapped: `{ "_value": "text", "_datatype": "string" }` | Flat string: `"text"` |
| Dates | Wrapped: `{ "_value": "2025-01-01", "_datatype": "dateTime" }` | Flat string: `"2025-01-01"` |
| Data types | Explicit via `_datatype` on each value | Not included |
| Nested objects (e.g. topics) | Object with `_about`, `prefLabel._value` | Object with `id`, `label` |
| Nested object structure | Single object or array depending on count | Always an array, even if one item |
| Resource type | `type` field with URI array | `type` in meta only (not on each item) |
| Field naming | Camel case, prefixed (e.g. `briefingIdentifier`) | Snake case (e.g. `identifier`) |

### Example: Single Item

**Existing LDA:**
```json
{
  "_about": "http://data.parliament.uk/resources/1234",
  "briefingIdentifier": { "_value": "CBP-1234", "_datatype": "string" },
  "title": { "_value": "Example Briefing", "_datatype": "string" },
  "date": { "_value": "2025-01-01T00:00:00", "_datatype": "dateTime" },
  "topic": [
    {
      "_about": "http://data.parliament.uk/terms/12345",
      "prefLabel": { "_value": "Defence" }
    }
  ],
  "type": ["http://purl.org/ontology/bibo/Report"]
}
```

**Data Library API:**
```json
{
  "id": "1234",
  "uri": "http://data.parliament.uk/resources/1234",
  "identifier": "CBP-1234",
  "title": "Example Briefing",
  "date": "2025-01-01T00:00:00",
  "topic": [
    {
      "id": "http://data.parliament.uk/terms/12345",
      "label": "Defence"
    }
  ]
}
```

## Response Wrapper

| Aspect | Existing LDA | Data Library API |
|--------|-------------|------------------|
| Top-level structure | `{ "format": "linked-data-api", "version": "0.2", "result": { ... } }` | `{ "meta": { ... }, "links": { ... }, "items": [ ... ] }` |
| Items location | `result.items` | `items` (top level) |
| Page size (default) | 10 | 20 |
| Page size parameter | `_pageSize` (max 500) | `per_page` (max 100) |
| Page number parameter | `_page` (zero-indexed) | `page` (one-indexed) |
| Pagination links | URL-based: `next`, `prev`, `first`, `last` inside `result` | URL-based: `links.self`, `links.first`, `links.last`, `links.next`, `links.prev` |
| Total count | `totalResults` inside `result` | `meta.total` |
| Dataset metadata | `result.isPartOf` with `hasPart` URL and definition | Not included |
| SPARQL query | Not exposed | Included in `meta.query` |
| Sort info | Not in response | Included in `meta.sort` |

### Example: Wrapper

**Existing LDA:**
```json
{
  "format": "linked-data-api",
  "version": "0.2",
  "result": {
    "_about": "http://eldaddp.azurewebsites.net/researchbriefings.json?_page=0",
    "definition": "http://eldaddp.azurewebsites.net/meta/researchbriefings.json",
    "extendedMetadataVersion": "http://eldaddp.azurewebsites.net/researchbriefings.json?...",
    "first": "http://eldaddp.azurewebsites.net/researchbriefings.json?_page=0",
    "hasPart": "http://eldaddp.azurewebsites.net/researchbriefings.json",
    "isPartOf": { ... },
    "items": [ ... ],
    "itemsPerPage": 10,
    "next": "http://eldaddp.azurewebsites.net/researchbriefings.json?_page=1",
    "page": 0,
    "startIndex": 1,
    "totalResults": 1234,
    "type": ["http://purl.org/linked-data/api/vocab#Page"]
  }
}
```

**Data Library API:**
```json
{
  "meta": {
    "total": 1234,
    "page": 1,
    "per_page": 20,
    "total_pages": 62,
    "items_in_response": 20,
    "type": "research-briefings",
    "sort": { "field": "date", "order": "desc", "sortable_fields": ["date", "title"] },
    "query": "CONSTRUCT { ... } WHERE { ... }"
  },
  "links": {
    "self": "http://example.com/api/v1/research-briefings?page=1",
    "first": "http://example.com/api/v1/research-briefings?page=1",
    "last": "http://example.com/api/v1/research-briefings?page=62",
    "next": "http://example.com/api/v1/research-briefings?page=2",
    "prev": null
  },
  "items": [ ... ]
}
```

## Single Resource (Show)

| Aspect | Existing LDA | Data Library API |
|--------|-------------|------------------|
| URL pattern | `/researchbriefings/:id.json` | `/api/v1/research-briefings/:id` |
| Response structure | `result.primaryTopic` containing the item | `meta` + `data` containing the item |
| Fields returned | All fields | All fields |

## Summary of Key Differences

1. **Value wrapping** - LDA wraps every value in `{ "_value": ..., "_datatype": ... }` objects; Data Library API uses flat values
2. **Identifiers** - LDA uses `_about` (full URI); Data Library API splits into `id` (short) and `uri` (full)
3. **Nested object labels** - LDA uses `prefLabel._value`; Data Library API uses `label`
4. **Pagination** - LDA is zero-indexed with `_page`/`_pageSize`; Data Library API is one-indexed with `page`/`per_page`
5. **Default page size** - LDA defaults to 10; Data Library API defaults to 20
6. **Response envelope** - LDA wraps everything in `format`/`version`/`result`; Data Library API uses `meta`/`links`/`items`
7. **Data types** - LDA includes explicit `_datatype` on values; Data Library API does not
8. **Nested arrays** - Data Library API always returns arrays for nested objects; LDA may return a single object when there is only one
