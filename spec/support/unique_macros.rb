# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    module InstanceMethods
      def with_global_config(config)
        was_config = SidekiqUniqueJobs.config
        SidekiqUniqueJobs.configure(config)
        yield
      ensure
        SidekiqUniqueJobs.configure(was_config)
      end

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
          around(:each) do |ex|
            with_sidekiq_options_for(worker_class, options, &ex)
          end
          class_exec(&block)
        end
      end

      def with_global_config(config = {}, &block)
        context "with global configuration #{config}" do
          around(:each) do |ex|
            with_global_config(config, &ex)
          end
          class_exec(&block)
        end
      end

      def with_default_worker_options(config = {}, &block)
        context "with default sidekiq options #{config}" do
          around(:each) do |ex|
            with_default_worker_options(config, &ex)
          end
          class_exec(&block)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include SidekiqUniqueJobs::RSpec::InstanceMethods
  config.extend SidekiqUniqueJobs::RSpec::ClassMethods
end
