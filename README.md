# Data Library API

A Rails API that provides a read only API to UK Parliament's linked data resources via SPARQL queries.

## Overview

This API acts as a middleware layer between clients and the Parliament SPARQL endpoint (`https://data-services.parliament.uk/sparql`). It provides:

- Paginated list and detail endpoints for resource types (Research Briefings, Deposited Papers, etc.)
- Filtering by taxonomy terms (topic, subject, publisher, etc.)
- Sorting by configurable fields
- JSON responses with consistent structure
- Built-in caching to reduce SPARQL endpoint load

## Quick Start

```bash
# Install dependencies
bundle install

# Start the server
bin/rails server

# Test an endpoint
curl http://localhost:3000/api/v1/research-briefings
```

## Deployment

The API is deployed to Heroku:

```bash
git push heroku main
```

Configuration via environment variables:
- `SPARQL_ENDPOINT` - Override the default SPARQL endpoint URL
- `SPARQL_SUBSCRIPTION_KEY` - Subscription key for the SPARQL endpoint (Ocp-Apim-Subscription-Key)
- `API_KEY` - API key for authenticating requests to this API (if not set, authentication is disabled)

### Authentication

When `API_KEY` is set, all requests must include a valid key in the `X-Api-Key` header:

```bash
curl -H "X-Api-Key: your-key-here" https://your-app.herokuapp.com/api/v1/research-briefings
```

Requests without a valid key will receive a `401 Unauthorized` response. Authentication is disabled when `API_KEY` is not set (e.g. local development).

## API Endpoints

### Root
- `GET /api/v1` - API overview and available resource types

### Resource Types
- `GET /api/v1/resource-types` - List all available resource types with documentation
- `GET /api/v1/resource-types/:id` - Documentation for a specific resource type

### Terms (Taxonomy)
- `GET /api/v1/terms?search=climate` - Search for terms by label
- `GET /api/v1/terms/:id` - Get a specific term

### Resources
Each resource type has list and detail endpoints:

- `GET /api/v1/research-briefings` - List research briefings
- `GET /api/v1/research-briefings/:id` - Get a specific research briefing
- `GET /api/v1/deposited-papers` - List deposited papers
- `GET /api/v1/deposited-papers/:id` - Get a specific deposited paper

### Query Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `page` | Page number (default: 1) | `?page=2` |
| `per_page` | Items per page (default: 20, max: 250) | `?per_page=50` |
| `fields` | Use `all` for complete data | `?fields=all` |
| `sort` | Field to sort by | `?sort=title` |
| `order` | Sort direction: `asc` or `desc` | `?order=asc` |
| `<term>` | Filter by taxonomy term ID | `?topic=12345` |

### Response Format

```json
{
  "meta": {
    "total_results": 1234,
    "results_per_page": 20,
    "current_page": 1,
    "total_pages": 62,
    "query": "PREFIX parl: <...> SELECT ..."
  },
  "links": {
    "self": "https://...",
    "first": "https://...",
    "next": "https://...",
    "last": "https://..."
  },
  "items": [...]
}
```

## Architecture

```
config/models.yml              # Single source of truth for resource types
       │
       ▼
lib/generators/model_generator.rb
       │
       ├──▶ app/models/<resource>.rb       # SPARQL queries, field definitions
       └──▶ config/resource_config.rb      # Route configuration

config/routes.rb               # Reads RESOURCE_CONFIG, creates routes
       │
       ▼
LinkedDataResourceController   # Generic controller for all resource types
       │
       ├──▶ SparqlFilterBuilder     # Build SPARQL filter from query params
       ├──▶ SparqlQueryBuilder      # Template substitution for queries
       ├──▶ SparqlGetObject         # Execute queries, instantiate models
       └──▶ JsonFormatterService    # Format response JSON
```

### Key Files

| File | Purpose |
|------|---------|
| `config/models.yml` | Define resource types, attributes, and filters |
| `app/models/linked_data_resource.rb` | Base class for all resources |
| `app/controllers/api/v1/linked_data_resource_controller.rb` | Generic controller |
| `app/services/sparql_*.rb` | SPARQL query building and execution |
| `lib/generators/model_generator.rb` | Generates model files from YAML config |

## Adding or Updating Resource Types

Resource types are defined in `config/models.yml`. See [docs/adding-resource-types.md](docs/adding-resource-types.md) for detailed instructions.

### Quick Guide

1. **Edit `config/models.yml`** - Add or modify a resource type definition:

```yaml
deposited-papers:
  description: Papers deposited in the House of Commons or House of Lords libraries
  sparql_type: "http://data.parliament.uk/schema/parl#DepositedPaper"
  base_uri: "http://data.parliament.uk/depositedpapers/{id}"
  sort_by: dateReceived
  sort_order: desc
  sortable_fields:
    - dateReceived
    - title

  attributes:
    title: dc-term:title
    dateReceived: parl:dateReceived
    depositingDepartment:
      uri: parl:department
      properties:
        label: skos:prefLabel

  index_attributes:
    - title
    - dateReceived

  required_attributes:
    - title
```

2. **Generate the model:**

```bash
bin/rails generate:models
```

3. **Test locally:**

```bash
bin/rails server
curl http://localhost:3000/api/v1/deposited-papers
```

4. **Deploy:**

```bash
git add -A
git commit -m "Add deposited papers resource type"
git push heroku main
```

## Technology Stack

- **Ruby** 3.4.4
- **Rails** 8.0 (API-only mode, no Active Record)
- **Puma** web server
- **Pagy** for pagination
- **JSON-LD** for linked data processing
- **Heroku** for hosting

## Caching

The API caches SPARQL query results to reduce load on the endpoint:

- List queries: 5 minutes
- Item queries: 15 minutes
- Count queries: 5 minutes

HTTP `Cache-Control` headers are also set for CDN/browser caching.

## Development

```bash
# Run tests
bin/rails test

# Check for security vulnerabilities
bundle exec brakeman

# Run linter
bundle exec rubocop
```

## SPARQL Prefixes

These prefixes are available in queries:

| Prefix | URI |
|--------|-----|
| `parl` | `http://data.parliament.uk/schema/parl#` |
| `dc-term` | `http://purl.org/dc/terms/` |
| `skos` | `http://www.w3.org/2004/02/skos/core#` |
| `rdfs` | `http://www.w3.org/2000/01/rdf-schema#` |
| `schema` | `http://schema.org/` |
| `foaf` | `http://xmlns.com/foaf/0.1/` |
| `nfo` | `http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#` |
