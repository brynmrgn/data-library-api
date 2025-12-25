Rails.application.routes.draw do
  RESOURCE_MODELS = LinkedDataResource.descendants.freeze

  get "up" => "rails/health#show", as: :rails_health_check

  # API v1 namespace
  namespace :api do
    namespace :v1 do
      root "root#index"

      RESOURCE_CONFIG.each do |key, config|
        path = config[:route_path]
        controller = config[:controller_name]

        get "#{path}", to: "object#index", defaults: { format: :json, controller_name: controller }, as: controller.to_sym
        get "#{path}/:id", to: "object#show", defaults: { format: :json, controller_name: controller }, as: controller.singularize.to_sym, constraints: { id: /\d+/ }
      end
    end
  end

  root "home#index"
end