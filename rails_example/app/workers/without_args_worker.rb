# frozen_string_literal: true

class WithoutArgsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: :custom_args

  def perform(_conditional = nil)
    sleep 2
  end

  def self.custom_args
    puts 'testing'
  end
end
