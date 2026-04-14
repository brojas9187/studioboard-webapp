Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  patch "locale/:locale", to: "locales#update", as: :switch_locale
  match "/auth/:provider/callback", to: "oauth_sessions#create", via: %i[get post]
  match "/auth/failure", to: "oauth_sessions#failure", via: %i[get post], as: :oauth_failure

  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resource :dashboard, only: :show, controller: :dashboard
  resource :billing, only: :show, controller: :billing do
    post :checkout
    post :portal
  end

  resources :organizations, only: %i[new create edit update] do
    patch :switch, on: :member
  end

  resources :memberships, only: %i[index create update destroy]

  resources :projects do
    resources :tasks, only: %i[create destroy] do
      patch :toggle, on: :member
    end
  end

  post "stripe/webhook", to: "stripe_webhooks#create"
end
