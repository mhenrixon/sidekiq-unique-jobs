# frozen_string_literal: true

module Benchmark
  module Trend
    # Clock that represents monotonic time
    module Clock
      # Microseconds per second
      MICROSECONDS_PER_SECOND = 1_000_000

      # Microseconds per 100ms
      MICROSECONDS_PER_100MS = 100_000

      class_definition = Class.new do
        def initialize
          super()
          @last_time = Time.now.to_f
          @lock = Mutex.new
        end

        if defined?(Process::CLOCK_MONOTONIC)
          # @api private
          def now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end
        else
          # @api private
          def now
            @lock.synchronize do
              current = Time.now.to_f
              if @last_time < current
                @last_time = current
              else # clock moved back in time
                @last_time += 0.000_001
              end
            end
          end
        end
      end

      MONOTONIC_CLOCK = class_definition.new
      private_constant :MONOTONIC_CLOCK

      # Current monotonic time
      #
      # @return [Float]
      #
      # @api public
      def now
        MONOTONIC_CLOCK.now
      end
      module_function :now

      # Measure time elapsed with a monotonic clock
      #
      # @return [Float]
      #
      # @public
      def measure
        before = now
        yield
        after = now
        after - before
      end
      module_function :measure
    end # Clock
  end # Perf
end # Benchmark
