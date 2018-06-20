# frozen_string_literal: true

module SidekiqUniqueJobs
  module Logging
    def logger
      SidekiqUniqueJobs.logger
    end

    def log_debug(message_or_exception = nil, &block)
      logger.debug(message_or_exception, &block)
    end

    def log_info(message_or_exception = nil, &block)
      logger.info(message_or_exception, &block)
    end

    def log_warn(message_or_exception = nil, &block)
      logger.warn(message_or_exception, &block)
    end

    def log_error(message_or_exception = nil, &block)
      logger.error(message_or_exception, &block)
    end

    def log_fatal(message_or_exception = nil, &block)
      logger.fatal(message_or_exception, &block)
    end
  end
end
