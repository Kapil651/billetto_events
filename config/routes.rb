Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "events#index"

  resources :events, only: :index do
    resource :vote, only: :create, controller: "event_votes"
  end

  get "sign-in", to: "sessions#new", as: :sign_in
  get "sign-up", to: "sessions#sign_up", as: :sign_up
  get "sign-out", to: "sessions#destroy", as: :sign_out
end
