require 'rspec/eventually/version'
require 'rspec/core'
require 'timeout'

module Rspec
  module Eventually
    class << self
      attr_accessor :timeout, :pause
    end
    self.timeout = 5
    self.pause = 0.1

    class FailedMatcherError < StandardError; end

    class Eventually
      attr_reader :timeout, :pause, :suppress_errors
      def by_suppressing_errors
        tap { @suppress_errors = true }
      end

      def initialize(target, custom_msg = nil)
        @target = target
        @tries = 0
        @negative = false
        @custom_msg = custom_msg
        @timeout = Rspec::Eventually.timeout
        @pause = Rspec::Eventually.pause
        @suppress_errors = false
      end

      def matches?(expected_block)
        Timeout.timeout(timeout) { eventually_matches? expected_block }
      rescue Timeout::Error
        @tries.zero? && raise('Timeout before first evaluation, use a longer `eventually` timeout \
          or shorter `eventually` pause')
      end

      def does_not_match?
        raise 'Use eventually_not instead of expect(...).to_not'
      end

      def failure_message
        msg = @custom_msg || @target.failure_message
        "After #{@tries} tries, the last failure message was:\n#{msg}"
      end

      def not
        tap { @negative = true }
      end

      def supports_block_expectations?
        true
      end

      def within(timeout)
        tap { @timeout = timeout }
      end

      def pause_for(pause)
        tap { @pause = pause }
      end

      private

      def eventually_matches?(expected_block)
        target_matches?(expected_block) || raise(FailedMatcherError)
      rescue StandardError => e
        raise if !e.is_a?(FailedMatcherError) && !suppress_errors
        sleep pause
        @tries += 1
        retry
      end

      def target_matches?(expected_block)
        result = @target.matches? expected_block.call
        @negative ? !result : result
      end
    end

    def eventually(target, custom_msg = nil)
      Eventually.new(target, custom_msg)
    end

    def eventually_not(target, custom_msg = nil)
      Eventually.new(target, custom_msg).not
    end

    RSpec.configure do |config|
      config.include ::Rspec::Eventually
    end
  end
end
