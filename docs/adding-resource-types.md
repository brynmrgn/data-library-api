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

deposited-papers:                                  # URL path (kebab-case)
  description: Papers deposited in the House of Commons or House of Lords libraries
  sparql_type: "http://data.parliament.uk/schema/parl#DepositedPaper"
  base_uri: "http://data.parliament.uk/depositedpapers/{id}"

  # Sorting
  sort_by: dateReceived                            # Default sort field
  sort_order: desc                                 # Default: desc
  sortable_fields:                                 # Fields users can sort by
    - dateReceived
    - title
    - identifier

  # Attributes - simple and nested
  attributes:
    # Simple properties (predicate only)
    title: dc-term:title
    identifier: dc-term:identifier
    abstract: dc-term:abstract
    dateReceived: parl:dateReceived

    # Nested properties (linked resources with their own properties)
    subject:
      uri: dc-term:subject
      properties:
        label: skos:prefLabel
    depositingDepartment:
      uri: parl:department
      properties:
        label: skos:prefLabel

  # Which attributes appear in list view (keep it light)
  index_attributes:
    - abstract
    - identifier
    - depositingDepartment
    - dateReceived

  # Required for an item to be valid
  required_attributes:
    - abstract
    - identifier
    - dateReceived

  # How users can filter results
  term_type_mappings:
    subject:
      predicate: dc-term:subject
      label: subject
    depositing-department:
      predicate: parl:department
      label: deposited by
```

## Step 2: Generate the Model

Run the generator:

```bash
bin/rails generate:models
```

This creates:
- `app/models/deposited_paper.rb` - Model with SPARQL queries
- Updates `config/resource_config.rb` - Route configuration

## Step 3: Verify

The new endpoints are automatically available:

```
GET /api/v1/deposited-papers           # List
GET /api/v1/deposited-papers/:id       # Show
GET /api/v1/resource-types/deposited-papers  # Documentation
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
| `description` | Human-readable description of the resource type |
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
cat app/models/deposited_paper.rb

# Test locally
bin/rails server
curl http://localhost:3000/api/v1/deposited-papers

# Or push to Heroku
git add -A && git commit -m "Add deposited papers resource type"
git push heroku main
```

## JSON-LD Frames

The generator automatically creates a JSON-LD frame for each resource type based on its attributes. Frames are used to shape the JSON-LD response from the SPARQL endpoint into a consistent structure.

### How Frames Work

A frame defines the expected structure of the JSON-LD response:

```json
{
  "@context": {
    "parl": "http://data.parliament.uk/schema/parl#",
    "dc-term": "http://purl.org/dc/terms/",
    ...
  },
  "@type": "http://data.parliament.uk/schema/parl#DepositedPaper",
  "@embed": "@always",
  "dc-term:title": { "@embed": "@always" },
  "parl:dateReceived": { "@embed": "@always" },
  ...
}
```

### Key Points

- **Dynamically generated**: Frames are built automatically from the `attributes` defined in `config/models.yml`. You don't need to write them manually.

- **Single frame per resource type**: The same frame is used for both list and detail views. This works because JSON-LD frames gracefully handle missing attributes - if a property isn't in the response, it's simply omitted from the output. This means the list query can return fewer fields than the detail query without needing separate frames.

- **Nested objects**: For attributes with sub-properties (like `topic` with a `label`), the frame ensures the nested structure is preserved in the output.

### Generated Output

When you run `bin/rails generate:models`, each model file includes a `FRAME` constant. You can inspect it in the generated model file (e.g., `app/models/deposited_paper.rb`).

## Architecture Overview

```
config/models.yml           # Single source of truth
       |
       v
lib/generators/model_generator.rb
       |
       +---> app/models/<resource>.rb      # SPARQL queries, constants, frame
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
