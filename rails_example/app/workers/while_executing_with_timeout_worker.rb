# frozen_string_literal: true

class WhileExecutingWithTimeoutWorker
  include Sidekiq::Worker

  sidekiq_options unique: :while_executing, lock_timeout: 5, unique_args: ->(args) { args.second }

  def perform(one, two)
    Sidekiq::Logging.with_context(self.class.name) do
      logger.info { "#{__method__}(#{one}, #{two})" }
    end
    sleep 10
  end
end
