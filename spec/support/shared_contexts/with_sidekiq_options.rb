# frozen_string_literal: true

RSpec.shared_context "with global config", with_global_config: true do
  let(:global_config) { {} }

  around do |example|
    SidekiqUniqueJobs.use_config(global_config, &example)
  end
end

RSpec.shared_context "with job options", with_job_options: true do
  let(:job_options) { {} }

  around do |example|
    job_class.use_options(job_options, &example)
  end
end

RSpec.shared_context "with sidekiq options", with_sidekiq_options: true do |**_options|
  let(:sidekiq_options) { {} }

  around do |example|
    Sidekiq.use_options(sidekiq_options, &example)
  end
end
