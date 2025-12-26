Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  # 取引管理（ユーザー画面）
  resources :simple_transactions, only: [:new, :create, :show]

  # API v1
  namespace :api do
    namespace :v1 do
      resources :simple_transactions, only: [:create, :update]
    end
  end

  # 管理者画面
  namespace :admin do
    resources :simple_transactions, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :cancel
      end
    end
    resources :api_call_logs, only: [:index, :show]
  end
end
