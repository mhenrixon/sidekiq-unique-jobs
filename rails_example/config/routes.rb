Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'
  get 'work/duplicate' => 'work#duplicate'
end
