class WorkController < ApplicationController
  def duplicate_simple
    4.times { SimpleWorker.perform_async(unique_argument) }

    redirect_to '/sidekiq'
  end

  def duplicate_slow
    4.times { SlowUntilExecutingWorker.perform_async(unique_argument) }

    redirect_to '/sidekiq'
  end

  def duplicate_nested
    4.times { SpawnSimpleWorker.perform_async(unique_argument) }

    redirect_to '/sidekiq'
  end

  def duplicate_without_args
    4.times { WithoutArgsWorker.perform_async }

    redirect_to '/sidekiq'
  end

  def unique_argument
    params[:id]
  end

  def safe_params
    params.permit!(:id)
  end
end
