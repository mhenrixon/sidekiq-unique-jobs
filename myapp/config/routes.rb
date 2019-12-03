# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq_unique_jobs/web'
  # require 'sidekiq-status/web'
  mount Sidekiq::Web, at: '/sidekiq'
  mount Coverband::Reporters::Web.new, at: '/coverage'

  get 'issues/:id' => 'issues#show'
  get "checkout" => 'checkout#new'
  post "checkout" => 'checkout#create'
end
