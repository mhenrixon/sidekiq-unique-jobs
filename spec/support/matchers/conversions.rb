# frozen_string_literal: true

require "time"

RSpec::Matchers.define :resemble_date do |expected|
  DATE_REGEX = /\A\d{4}-\d{2}-\d{2}\Z/.freeze
  ISO8601_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\Z/.freeze
  UNIX_REGEX = /\A\d{10}.\d{7}\Z/.freeze

  match do |date_or_str|
    @actual = date_or_str
    case date_or_str
    when Date, Time, DateTime, UNIX_REGEX
      true
    when DATE_REGEX, ISO8601_REGEX
      true
    when String
      begin
        Time.iso8601(date_or_str)
        true
      rescue ArgumentError
        false
      end
    end
  end

  description do
    "resemble date #{expected.inspect}"
  end

  failure_message do
    "#{@actual.inspect} does not resemble a Date or Timestamp"
  end
end
