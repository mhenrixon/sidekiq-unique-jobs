# frozen_string_literals: true

module Lumberjack
  # The standard severity levels for logging messages.
  module Severity
    # Backward compatibilty with 1.0 API
    DEBUG = ::Logger::Severity::DEBUG
    INFO = ::Logger::Severity::INFO
    WARN = ::Logger::Severity::WARN
    ERROR = ::Logger::Severity::ERROR
    FATAL = ::Logger::Severity::FATAL
    UNKNOWN = ::Logger::Severity::UNKNOWN

    SEVERITY_LABELS = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN].freeze

    class << self
      def level_to_label(severity)
        SEVERITY_LABELS[severity] || SEVERITY_LABELS.last
      end

      def label_to_level(label)
        SEVERITY_LABELS.index(label.to_s.upcase) || UNKNOWN
      end
    end
  end
end
