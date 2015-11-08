class WorkController < ApplicationController
  def duplicate
    SimpleWorker.perform_async(1)
    4.times do |_x|
      SpawnSimpleWorker.perform_async(1)
    end

    redirect_to '/sidekiq'
  end
end
