# Pagy core
# require 'pagy'  # usually loaded by bundler

# for pagy 9.4.0 - do not load extras unless needed
require 'pagy/extras/array'
require 'pagy/extras/countless'
# require 'pagy/extras/overflow'
# require 'pagy/extras/bootstrap'  # or other frontend

# customize Pagy default settings:

Pagy::DEFAULT[:items]       = $DEFAULT_RESULTS_PER_PAGE  # default per-page
Pagy::DEFAULT[:max_items]   = $MAX_RESULTS_PER_PAGE      # max per-page