# frozen_string_literal: true

module Lumberjack
  # A context is used to store tags that are then added to all log entries within a block.
  class Context
    attr_reader :tags

    def initialize(parent_context = nil)
      @tags = {}
      @tags.merge!(parent_context.tags) if parent_context
    end

    # Set tags on the context.
    def tag(tags)
      tags.each do |key, value|
        @tags[key.to_s] = value
      end
    end

    # Get a context tag.
    def [](key)
      @tags[key.to_s]
    end

    # Set a context tag.
    def []=(key, value)
      @tags[key.to_s] = value
    end

    # Clear all the context data.
    def reset
      @tags.clear
    end
  end
end
