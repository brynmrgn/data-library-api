# Adding New Resource Types

This guide explains how to add new resource types to the Data Library API.

## Overview

Resource types are defined in `config/models.yml`. The model generator (`rake generate:models`) creates:
- Model class with SPARQL queries and JSON-LD frame
- Route configuration for API endpoints

## Step 1: Define the Resource Type

Add a new entry to `config/models.yml`:

```yaml
# config/models.yml

oral-questions:                                    # URL path (kebab-case)
  sparql_type: "http://data.parliament.uk/schema/parl#OralQuestion"
  base_uri: "http://data.parliament.uk/resources/{id}"

  # Sorting
  sort_by: date                                    # Default sort field
  sort_order: desc                                 # Default: desc
  sortable_fields:                                 # Fields users can sort by
    - date
    - title

  # Optional: Filter to exclude items (e.g., withdrawn)
  required_filter:
    predicate: parl:status
    value: published

  # Attributes - simple and nested
  attributes:
    # Simple properties (predicate only)
    title: dc-term:title
    date: dc-term:date
    identifier: dc-term:identifier

    # Nested properties (linked resources with their own properties)
    topic:
      uri: parl:topic
      properties:
        label: skos:prefLabel
    member:
      uri: parl:member
      properties:
        name: foaf:name
        party: parl:party

  # Which attributes appear in list view (keep it light)
  index_attributes:
    - title
    - date
    - member

  # Required for an item to be valid
  required_attributes:
    - title
    - identifier

  # How users can filter results
  term_type_mappings:
    topic:
      predicate: parl:topic
      label: topic
    member:
      predicate: parl:member
      label: asked by
      nested: true                                 # For sub-objects
      nested_predicate: rdfs:seeAlso               # Link to term
```

## Step 2: Generate the Model

Run the generator:

```bash
bin/rails generate:models
```

This creates:
- `app/models/oral_question.rb` - Model with SPARQL queries
- Updates `config/resource_config.rb` - Route configuration

## Step 3: Verify

The new endpoints are automatically available:

```
GET /api/v1/oral-questions           # List
GET /api/v1/oral-questions/:id       # Show
GET /api/v1/resource-types/oral-questions  # Documentation
```

## Configuration Reference

### Required Fields

| Field | Description |
|-------|-------------|
| `sparql_type` | Full RDF type URI |
| `base_uri` | URI template with `{id}` placeholder |
| `sort_by` | Default sort field (must be in attributes) |
| `attributes` | Map of attribute names to RDF predicates |
| `index_attributes` | Fields for list view |
| `required_attributes` | Fields that must exist |

### Optional Fields

| Field | Description |
|-------|-------------|
| `sort_order` | Default sort direction: `asc` or `desc` (default: `desc`) |
| `sortable_fields` | List of fields users can sort by |
| `required_filter` | Predicate/value to always filter by |
| `term_type_mappings` | How to filter by taxonomy terms |

### Attribute Types

**Simple attribute:**
```yaml
title: dc-term:title
```

**Nested attribute (with sub-properties):**
```yaml
author:
  uri: dc-term:creator
  properties:
    given_name: schema:givenName
    family_name: schema:familyName
    ses_id: rdfs:seeAlso
```

### Term Type Mappings

For simple term references:
```yaml
topic:
  predicate: parl:topic
  label: topic
```

For nested sub-objects (where the term is linked via another predicate):
```yaml
author:
  predicate: dc-term:creator
  label: Author
  nested: true
  nested_predicate: rdfs:seeAlso
```

## Common Prefixes

These prefixes are available in SPARQL queries:

| Prefix | URI |
|--------|-----|
| `parl` | `http://data.parliament.uk/schema/parl#` |
| `dc-term` | `http://purl.org/dc/terms/` |
| `skos` | `http://www.w3.org/2004/02/skos/core#` |
| `rdfs` | `http://www.w3.org/2000/01/rdf-schema#` |
| `schema` | `http://schema.org/` |
| `foaf` | `http://xmlns.com/foaf/0.1/` |
| `nfo` | `http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#` |

## Updating Existing Types

1. Edit the entry in `config/models.yml`
2. Run `bin/rails generate:models`
3. Commit the updated model file

## Testing Changes

After generating:

```bash
# Check the generated model
cat app/models/oral_question.rb

# Test locally
bin/rails server
curl http://localhost:3000/api/v1/oral-questions

# Or push to Heroku
git add -A && git commit -m "Add oral questions resource type"
git push heroku main
```

## Architecture Overview

```
config/models.yml           # Single source of truth
       |
       v
lib/generators/model_generator.rb
       |
       +---> app/models/<resource>.rb      # SPARQL queries, constants
       +---> config/resource_config.rb     # Route configuration

config/routes.rb            # Reads RESOURCE_CONFIG, creates routes
       |
       v
LinkedDataResourceController  # Generic controller for all types
       |
       +---> SparqlFilterBuilder    # Build filter from ?topic=123
       +---> SparqlQueryBuilder     # Template substitution
       +---> SparqlGetObject        # Execute query, instantiate models
       +---> JsonFormatterService   # Format response JSON
```
