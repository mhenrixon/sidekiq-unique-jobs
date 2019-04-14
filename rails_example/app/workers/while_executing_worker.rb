# frozen_string_literal: true

class WhileExecutingWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options unique: :while_executing, lock_timeout: 15

  def perform(sleepy_time)
    sleepy_time = sleepy_time.to_i
    sleep sleepy_time if sleepy_time.positive?
    Post.create!(title: "Some Random post that took #{sleepy_time} seconds to create", body: "The job_id was #{jid}")
  end
end
