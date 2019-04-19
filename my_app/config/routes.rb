# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq_unique_jobs/web'
  require 'sidekiq-status/web'
  mount Sidekiq::Web, at: '/sidekiq'

  get 'issue/384'                                    => 'issue#384'
end
