# frozen_string_literal: true

module Lumberjack
  # Class for formatting tags. You can register a default formatter and tag
  # name specific formatters. Formatters can be either `Lumberjack::Formatter`
  # objects or any object that responds to `call`.
  #
  # tag_formatter = Lumberjack::TagFormatter.new.default(Lumberjack::Formatter.new)
  # tag_formatter.add(["password", "email"]) { |value| "***" }
  # tag_formatter.add("finished_at", Lumberjack::Formatter::DateTimeFormatter.new("%Y-%m-%dT%H:%m:%S%z"))
  class TagFormatter
    def initialize
      @formatters = {}
      @default_formatter = nil
    end

    # Add a default formatter applied to all tag values. This can either be a Lumberjack::Formatter
    # or an object that responds to `call` or a block.
    def default(formatter = nil, &block)
      formatter ||= block
      formatter = dereference_formatter(formatter)
      @default_formatter = formatter
      self
    end

    # Remove the default formatter.
    def remove_default
      @default_formatter = nil
      self
    end

    # Add a formatter for specific tag names. This can either be a Lumberjack::Formatter
    # or an object that responds to `call` or a block. The default formatter will not be
    # applied.
    def add(names, formatter = nil, &block)
      formatter ||= block
      formatter = dereference_formatter(formatter)
      if formatter.nil?
        remove(key)
      else
        Array(names).each do |name|
          @formatters[name.to_s] = formatter
        end
      end
      self
    end

    # Remove formatters for specific tag names. The default formatter will still be applied.
    def remove(names)
      Array(names).each do |name|
        @formatters.delete(name.to_s)
      end
      self
    end

    # Remove all formatters.
    def clear
      @default_formatter = nil
      @formatters.clear
      self
    end

    # Format a hash of tags using the formatters
    def format(tags)
      return nil if tags.nil?
      if @default_formatter.nil? && (@formatters.empty? || (@formatters.keys & tags.keys).empty?)
        tags
      else
        formatted = {}
        tags.each do |name, value|
          formatter = (@formatters[name.to_s] || @default_formatter)
          if formatter.is_a?(Lumberjack::Formatter)
            value = formatter.format(value)
          elsif formatter.respond_to?(:call)
            value = formatter.call(value)
          end
          formatted[name.to_s] = value
        end
        formatted
      end
    end

    private

    def dereference_formatter(formatter)
      if formatter.is_a?(TaggedLoggerSupport::Formatter)
        formatter.__formatter
      elsif formatter.is_a?(Symbol)
        formatter_class_name = "#{formatter.to_s.gsub(/(^|_)([a-z])/) { |m| $~[2].upcase }}Formatter"
        Formatter.const_get(formatter_class_name).new
      else
        formatter
      end
    end
  end
end
