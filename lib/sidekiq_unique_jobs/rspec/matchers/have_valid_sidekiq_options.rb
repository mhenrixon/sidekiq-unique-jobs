# frozen_string_literal: true

module SidekiqUniqueJobs
  module RSpec
    #
    # Module Matchers provides RSpec matcher for your workers
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    module Matchers
      #
      # Class BeLockable validates the unique/lock configuration for your worker.
      #
      # @author Mikael Henriksson <mikael@zoolutions.se>
      #
      class HaveValidSidekiqOptions
        attr_reader :worker, :lock_config, :sidekiq_options

        def matches?(worker)
          @worker          = worker
          @sidekiq_options = worker.get_sidekiq_options
          @lock_config     = SidekiqUniqueJobs.validate_worker(sidekiq_options)
          lock_config.valid?
        end

        def failure_message
          <<~FAILURE_MESSAGE
            Expected #{worker} to have valid sidekiq options but found the following problems:
            #{errors_as_string}
          FAILURE_MESSAGE
        end

        def description
          "have valid sidekiq options"
        end

        def errors_as_string
          @errors_as_string ||= begin
            error_msg = +"\t"
            error_msg << lock_config.errors.map { |key, val| "#{key}: :#{val}" }.join("\n\t")
            error_msg
          end
        end
      end

      def have_valid_sidekiq_options(*args) # rubocop:disable Naming/PredicateName
        HaveValidSidekiqOptions.new(*args)
      end
    end
  end
end
