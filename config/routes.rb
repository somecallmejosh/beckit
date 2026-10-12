Rails.application.routes.draw do
  resources :situations do
    resource :restoration, only: :create, module: :situations
  end
  resources :distortions
  resource :insights, only: :show
  resource :settings, only: %i[ edit update ]
  namespace :settings do
    resource :password, only: :update
    resource :account, only: :destroy
  end
  resource :registration, only: %i[ new create ]
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Installable via the manifest. No service worker on purpose: one could cache journal pages on the device.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "privacy" => "pages#privacy"
  root "pages#home"
end
