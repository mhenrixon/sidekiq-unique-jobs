# frozen_string_literal: true

require "objspace"

require_relative "malloc/allocation"
require_relative "malloc/allocation_set"
require_relative "malloc/allocation_result"
require_relative "malloc/version"

module Benchmark
  class Malloc
    class Error < StandardError; end

    attr_reader :generation

    # It runs Ruby VM before tracing object allocations
    #
    # @api public
    attr_reader :warmup

    # Trace memory allocations
    #
    # @api public
    def self.trace(&work)
      Malloc.new.run(&work)
    end

    # Create a memory allocation tracer
    #
    # @api public
    def initialize(warmup: 0)
      @warmup = warmup
      @running = false
      @alloc_path = ::File.join(__FILE__[0...-3], "allocation.rb")
    end

    # @api private
    def check_running
      unless @running
        raise Error, "not started yet"
      end
    end

    # Start allocation tracing
    #
    # @example
    #   malloc = Malloc.new
    #   malloc.start
    #
    # @api public
    def start
      if @running
        raise Error, "already running"
      end

      GC.start
      GC.disable
      @generation = GC.count
      @running = true
      @existing_ids = []
      ObjectSpace.each_object do |object|
        @existing_ids << object.__id__
      end
      ObjectSpace.trace_object_allocations_start
    end

    # Stop allocation tracing if currently running
    #
    # @example
    #   Malloc.stop
    #
    # @api public
    def stop
      check_running

      ObjectSpace.trace_object_allocations_stop
      allocated = collect_allocations
      retained  = []
      @running  = false
      GC.enable
      GC.start

      ObjectSpace.each_object do |object|
        next unless ObjectSpace.allocation_generation(object) == generation
        next unless allocated.key?(object.__id__)
        retained << allocated[object.__id__]
      end

      ObjectSpace.trace_object_allocations_clear

      AllocationResult.new(AllocationSet.new(allocated.values),
                            AllocationSet.new(retained))
    end

    # Gather allocation stats of Ruby code inside of the block
    #
    # @example
    #   malloc = Malloc.new
    #   malloc.run { ... }
    #
    # @return [Malloc::Result]
    #
    # @api public
    def run(&work)
      start
      warmup.times { yield }

      begin
        yield
      rescue Exception
        ObjectSpace.trace_object_allocations_stop
        GC.enable
        raise
      else
        stop
      end
    end

    private

    # @api private
    def collect_allocations
      allocations = {}
      ObjectSpace.each_object do |object|
        next unless ObjectSpace.allocation_generation(object) == generation
        next if ObjectSpace.allocation_sourcefile(object).nil?
        next if ObjectSpace.allocation_sourcefile(object) == __FILE__
        next if ObjectSpace.allocation_sourcefile(object) == @alloc_path
        next if @existing_ids.include?(object.__id__)

        allocations[object.__id__] = Allocation.new(object)
      end
      allocations
    end
  end # Malloc
end # Benchmark
