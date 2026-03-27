# frozen_string_literal: true

Rails.application.routes.draw do
  require "sidekiq_unique_jobs/web"

  mount Sidekiq::Web, at: "/sidekiq"

  resources :locks, only: [:index, :show] do
    collection do
      post :enqueue
      delete :flush
    end
  end

  root to: "locks#index"
end
