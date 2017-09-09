# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'

  get 'work'                                         => 'work#index'

  get 'work/duplicate_simple'                        => 'work#duplicate_simple'
  get 'work/duplicate_slow'                          => 'work#duplicate_slow'
  get 'work/duplicate_nested'                        => 'work#duplicate_nested'
  get 'work/duplicate_without_args'                  => 'work#duplicate_without_args'
  get 'work/duplicate_with_args'                     => 'work#duplicate_with_args'
  get 'work/duplicate_while_executing'               => 'work#duplicate_while_executing'
  get 'work/duplicate_while_executing_with_timeout'  => 'work#duplicate_while_executing_with_timeout'
end
