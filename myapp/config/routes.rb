# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  authenticate :user, ->(u) { u.admin? } do
    require "sidekiq/web"
    require "sidekiq_unique_jobs/web"
    mount Sidekiq::Web, at: "/sidekiq"
  end
  mount Coverband::Reporters::Web.new, at: "/coverage"

  get "issues/:id" => "issues#show"
  get "checkout" => "checkout#new"
  post "checkout" => "checkout#create"
end
