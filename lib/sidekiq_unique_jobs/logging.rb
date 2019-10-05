# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module for reducing the number of uses of logger.
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Logging
    def self.included(base)
      base.send(:extend, self)
    end

    #
    # A convenience method for using the configured gem logger
    #
    # @see SidekiqUniqueJobs#.logger
    #
    # @return [Logger]
    #
    def logger
      SidekiqUniqueJobs.logger
    end

    #
    # Logs a message at debug level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_debug(message_or_exception = nil, &block)
      logger.debug(message_or_exception, &block)
      nil
    end

    #
    # Logs a message at info level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_info(message_or_exception = nil, &block)
      logger.info(message_or_exception, &block)
      nil
    end

    #
    # Logs a message at warn level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_warn(message_or_exception = nil, &block)
      logger.warn(message_or_exception, &block)
      nil
    end

    #
    # Logs a message at error level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_error(message_or_exception = nil, &block)
      logger.error(message_or_exception, &block)
      nil
    end

    #
    # Logs a message at fatal level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_fatal(message_or_exception = nil, &block)
      logger.fatal(message_or_exception, &block)
      nil
    end

    #
    # Wraps the middleware logic with context aware logging
    #
    #
    # @return [void]
    #
    # @yieldreturn [void] yield to the middleware instance
    #
    def with_logging_context
      with_configured_loggers_context do
        return yield
      end
      nil # Need to make sure we don't return anything here
    end

    #
    # Attempt to setup context aware logging for the given logger
    #
    #
    # @return [void]
    #
    # @yield
    #
    def with_configured_loggers_context
      logger_method.call(logging_context) { yield }
    end

    #
    # Setup some variables to add to each log line
    #
    #
    # @return [Hash] the context to use for each log line
    #
    def logging_context
      raise NotImplementedError, "#{__method__} needs to be implemented in #{self.class}"
    end

    private

    def logger_method
      @logger_method ||= Sidekiq::Context.method(:with)         if defined?(Sidekiq::Context)
      @logger_method ||= logger.method(:with_context)           if logger_respond_to_with_context?
      @logger_method ||= Sidekiq::Logging.method(:with_context) if defined?(Sidekiq::Logging)
      @logger_method ||= method(:fake_logger_method)
    end

    def logger_context_hash?
      defined?(Sidekiq::Context) || logger_respond_to_with_context?
    end

    def logger_respond_to_with_context?
      logger.respond_to?(:with_context)
    end

    def fake_logger_method(context)
      logger.warn "Received #{context} for logs but don't know how to setup the logging context." \
                  " Please open a feature request:" \
                  " https://github.com/mhenrixon/sidekiq-unique-jobs/issues/new?template=feature_request.md"

      yield
    end
  end
end
