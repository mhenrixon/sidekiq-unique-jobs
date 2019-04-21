# frozen_string_literal: true

class IssuesController < ApplicationController
  def index
    render :index
  end

  def show
    number_to_perform.times do
      if worker_args.present?
        worker_class.perform_async(worker_args)
      else
        worker_class.perform_async
      end
    end

    redirect_to '/sidekiq'
  end

  private

  def worker_class
    @worker_class ||= "Issue#{params.permit(:id)}".constantize
  end

  def worker_args
    params.permit(:args) || nil
  end

  def number_to_perform
    params.permit(:times) || 4
  end
end
