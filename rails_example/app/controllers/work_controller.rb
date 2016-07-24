class WorkController < ApplicationController
  def duplicate_simple
    4.times { SimpleWorker.perform_async(1) }

    redirect_to '/sidekiq'
  end

  def duplicate_slow
    4.times { SlowUntilExecutingWorker.perform_async(1) }

    redirect_to '/sidekiq'
  end

  def duplicate_nested
    4.times { SpawnSimpleWorker.perform_async(1) }

    redirect_to '/sidekiq'
  end
end
