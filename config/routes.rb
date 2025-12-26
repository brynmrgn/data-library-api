Rails.application.routes.draw do
  RESOURCE_MODELS = LinkedDataResource.descendants.freeze

  get "up" => "rails/health#show", as: :rails_health_check

  # API v1 namespace
  namespace :api do
    namespace :v1 do
      root "root#index"

      # Resource type documentation
      get "resource-types", to: "resource_types#index"
      get "resource-types/:id", to: "resource_types#show"

      # Terms lookup
      get "terms", to: "terms#index"
      get "terms/:id", to: "terms#show", constraints: { id: /\d+/ }

      RESOURCE_CONFIG.each do |path, config|
        controller = config[:controller_name]

        get "#{path}", to: "linked_data_resource#index", defaults: { format: :json, controller_name: controller }, as: controller.to_sym
        get "#{path}/:id", to: "linked_data_resource#show", defaults: { format: :json, controller_name: controller }, as: controller.singularize.to_sym, constraints: { id: /\d+/ }
      end
    end
  end

  root "home#index"
end