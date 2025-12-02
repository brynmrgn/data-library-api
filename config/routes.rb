Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "deposited-papers", to: "deposited_papers#index"
  get "deposited-papers/:term_type/:id", to: "deposited_papers#index"
  get "deposited-papers/:id", to: "deposited_papers#show"

  get "research-briefings", to: "research_briefings#index"
  get "research-briefings/:term_type/:id", to: "research_briefings#index"
  get "research-briefings/:id", to: "research_briefings#show"

  get "/types", to: "resource_types#index"


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
