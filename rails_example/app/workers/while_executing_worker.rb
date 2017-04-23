# frozen_string_literal: true

class WhileExecutingWorker
  include Sidekiq::Worker

  sidekiq_options unique: :while_executing

  def perform(one, two)
    Sidekiq::Logging.with_context(self.class.name) do
      logger.info { "#{__method__}(#{one}, #{two})" }
    end
    sleep 10
  end
end
