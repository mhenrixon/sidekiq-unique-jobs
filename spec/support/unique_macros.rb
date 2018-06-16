# frozen_string_literal: true

# rubocop:disable RSpec/EmptyExampleGroup
module SidekiqUniqueJobs
  module RSpec
    module InstanceMethods
      def with_sidekiq_options_for(worker_class, options)
        worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        if worker_class.respond_to?(:sidekiq_options)
          was_options = worker_class.get_sidekiq_options
          worker_class.sidekiq_options(options)
        end
        yield
      ensure
        worker_class.sidekiq_options_hash = was_options if worker_class.respond_to?(:sidekiq_options_hash=)
      end

      def with_default_worker_options(options)
        was_options = Sidekiq.default_worker_options
        Sidekiq.default_worker_options.clear
        Sidekiq.default_worker_options = options

        yield
      ensure
        Sidekiq.default_worker_options.clear
        Sidekiq.default_worker_options = was_options
      end
    end

    module ClassMethods
      def with_sidekiq_options_for(worker_class, options = {}, &block)
        context "with sidekiq options #{options}" do
          around do |example|
            with_sidekiq_options_for(worker_class, options, &example)
          end

          class_exec(&block)
        end
      end

      def with_default_worker_options(config = {}, &block)
        context "with default sidekiq options #{config}" do
          around do |example|
            with_default_worker_options(config, &example)
          end

          class_exec(&block)
        end
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup

RSpec.configure do |config|
  config.include SidekiqUniqueJobs::RSpec::InstanceMethods
  config.extend SidekiqUniqueJobs::RSpec::ClassMethods
end
