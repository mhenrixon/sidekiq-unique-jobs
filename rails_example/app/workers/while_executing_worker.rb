# frozen_string_literal: true

class WhileExecutingWorker
  include Sidekiq::Worker

  sidekiq_options unique: :while_executing

  def perform(_one, _two)
    Sidekiq::Logging.with_context(self.class.name) do
      logger.debug { "#{__method__}(#{some_args})" }
    end
    sleep 10
  end
end
