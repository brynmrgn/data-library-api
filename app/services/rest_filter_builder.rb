# app/services/rest_filter_builder.rb
#
# Builds upstream REST API query parameters from request parameters.
# Analogous to SparqlFilterBuilder but for REST-sourced resources.
#
# Uses the model's FILTER_MAPPINGS constant to translate our parameter names
# to the upstream API's parameter names, applying defaults where configured.
#
# @example
#   # Given FILTER_MAPPINGS: { house: { upstream_param: "House", default: nil } }
#   # and params: { house: "Commons" }
#   RestFilterBuilder.new(Committee, params).build
#   # => { "House" => "Commons" }
#
class RestFilterBuilder
  def initialize(model_class, params)
    @model_class = model_class
    @params = params
  end

  # Builds a hash of upstream API query parameters
  #
  # @return [Hash] Query parameters for the upstream API
  #
  def build
    return {} unless @model_class.const_defined?(:FILTER_MAPPINGS)

    query_params = {}

    @model_class::FILTER_MAPPINGS.each do |our_param, config|
      value = @params[our_param.to_s].presence || config[:default]
      next unless value

      query_params[config[:upstream_param]] = value
    end

    query_params
  end
end
