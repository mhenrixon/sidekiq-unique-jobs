# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  authenticate :user, ->(u) { u.admin? } do
    require "sidekiq_unique_jobs/web"

    mount Sidekiq::Web, at: "/sidekiq"
  end

  get "issues/:id" => "issues#show"

  root to: "home#index"
end
