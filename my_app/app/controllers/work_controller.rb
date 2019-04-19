# frozen_string_literal: true

class WorkController < ApplicationController
  def index
    render :index
  end

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

  def duplicate_with_args
    4.times { WithoutArgsWorker.perform_async 1 }

    redirect_to '/sidekiq'
  end

  def duplicate_while_executing
    params[:attempts].to_i.times { WhileExecutingWorker.perform_async(params[:sleepy_time]) }

    redirect_to '/sidekiq'
  end

  def duplicate_while_executing_with_timeout
    4.times { WhileExecutingWithTimeoutWorker.perform_async(1, 2) }

    redirect_to '/sidekiq'
  end

  private

  def unique_argument
    params[:id]
  end

  def safe_params
    params.permit!(:id)
  end
end
