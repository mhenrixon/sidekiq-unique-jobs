# frozen_string_literal: true

RSpec.shared_context "with sidekiq options", with_sidekiq_options: true do
  let(:sidekiq_options) { {} }
  let(:worker_options)  { {} }
  let(:worker_class)    { UntilExecutedJob }

  around do |example|
    Sidekiq.use_options(sidekiq_options) do
      worker_class.use_options(worker_options) do
        example.run
      end
    end
  end
end
