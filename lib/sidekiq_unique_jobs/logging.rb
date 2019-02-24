# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module for reducing the number of uses of logger.
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Logging
    # A convenience method for using the configured logger
    def logger
      SidekiqUniqueJobs.logger
    end

    # Logs a message at debug level
    # @param message_or_exception [String, Exception] the message or exception to log
    # @yield the message or exception to use for log message
    #   Used for compatibility with logger
    def log_debug(message_or_exception = nil, &block)
      logger.debug(message_or_exception, &block)
    end

    # Logs a message at info level
    # @param message_or_exception [String, Exception] the message or exception to log
    # @yield the message or exception to use for log message
    #   Used for compatibility with logger
    def log_info(message_or_exception = nil, &block)
      logger.info(message_or_exception, &block)
    end

    # Logs a message at warn level
    # @param message_or_exception [String, Exception] the message or exception to log
    # @yield the message or exception to use for log message
    #   Used for compatibility with logger
    def log_warn(message_or_exception = nil, &block)
      logger.warn(message_or_exception, &block)
    end

    # Logs a message at error level
    # @param message_or_exception [String, Exception] the message or exception to log
    # @yield the message or exception to use for log message
    #   Used for compatibility with logger
    def log_error(message_or_exception = nil, &block)
      logger.error(message_or_exception, &block)
    end

    # Logs a message at fatal level
    # @param message_or_exception [String, Exception] the message or exception to log
    # @yield the message or exception to use for log message
    #   Used for compatibility with logger
    def log_fatal(message_or_exception = nil, &block)
      logger.fatal(message_or_exception, &block)
    end

    def logging_context(middleware_class, job_hash)
      digest = job_hash["unique_digest"]
      if defined?(Sidekiq::Logging)
        "#{middleware_class} #{"DIG-#{digest}" if digest}"
      else
        { middleware: middleware_class, unique_digest: digest }
      end
    end
  end
end
