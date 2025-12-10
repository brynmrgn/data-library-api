Rails.application.routes.draw do
  RESOURCE_TYPES = {
    'deposited-papers' => 'deposited_papers',
    'research-briefings' => 'research_briefings'
  }.freeze unless defined?(RESOURCE_TYPES)
  
  get "up" => "rails/health#show", as: :rails_health_check
  
  RESOURCE_TYPES.each do |path, controller|
    get "#{path}/feed", to: "object#feed", defaults: { format: :rss, controller_name: controller }, as: "feed_#{controller}".to_sym
    get "#{path}", to: "object#index", defaults: { controller_name: controller }, as: controller.to_sym
    get "#{path}/:term_type/:id", to: "object#index", defaults: { controller_name: controller }
    get "#{path}/:id", to: "object#show", defaults: { controller_name: controller }, as: controller.singularize.to_sym, constraints: { id: /\d+/ }  end

  get "/types", to: "resource_types#index"
  root "home#index"
end