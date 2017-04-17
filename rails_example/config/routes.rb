Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'
  get 'work/duplicate_simple' => 'work#duplicate_simple'
  get 'work/duplicate_nested' => 'work#duplicate_nested'
  get 'work/duplicate_without_args' => 'work#duplicate_without_args'
end
