# frozen_string_literal: true

require_relative "clock"
require_relative "cpu_result"

module Benchmark
  module Perf
    # Measure length of time the work could take on average
    #
    # @api public
    module Execution
      # Check if measurements need to run in subprocess
      #
      # @api private
      def run_in_subprocess?
        ENV["RUN_IN_SUBPROCESS"] != 'false' && Process.respond_to?(:fork)
      end
      module_function :run_in_subprocess?

      # Isolate run in subprocess
      #
      # @example
      #   iteration.run_in_subproces { ... }
      #
      # @return [Float]
      #   the elapsed time of the measurement
      #
      # @api private
      def run_in_subprocess(subprocess: true, io: nil)
        return yield unless subprocess && Process.respond_to?(:fork)
        return yield unless run_in_subprocess?

        reader, writer = IO.pipe
        reader.binmode
        writer.binmode

        pid = Process.fork do
          GC.start
          GC.disable if ENV['BENCH_DISABLE_GC']

          begin
            reader.close
            time = yield
            io.print "%9.6f" % data if io
            Marshal.dump(time, writer)
          rescue => error
            Marshal.dump(error, writer)
          ensure
            GC.enable if ENV['BENCH_DISABLE_GC']
            writer.close
            exit # allow finalizers to run
          end
        end

        writer.close unless writer.closed?
        Process.waitpid(pid)
        data = Marshal.load(reader)
        reader.close
        raise data if data.is_a?(Exception)
        data
      end
      module_function :run_in_subprocess

      # Run warmup measurement
      #
      # @param [Numeric] warmup
      #   the warmup time
      #
      # @api private
      def run_warmup(warmup: 1, io: nil, subprocess: true, &work)
        GC.start

        warmup.times do
          run_in_subprocess(io: io, subprocess: subprocess) do
            Clock.measure(&work)
          end
        end
      end
      module_function :run_warmup

      # Perform work x times
      #
      # @param [Integer] repeat
      #   how many times to repeat the code measuremenets
      #
      # @example
      #   ExecutionTime.run(repeat: 10) { ... }
      #
      # @return [Array[Float, Float]]
      #   average and standard deviation
      #
      # @api public
      def run(repeat: 1, io: nil, warmup: 1, subprocess: true, &work)
        check_greater(repeat, 0)

        result = CPUResult.new

        run_warmup(warmup: warmup, io: io, subprocess: subprocess, &work)

        repeat.times do
          GC.start
          result << run_in_subprocess(io: io, subprocess: subprocess) do
            Clock.measure(&work)
          end
        end

        io.puts if io

        result
      end
      module_function :run

      # Check if expected value is greater than minimum
      #
      # @param [Numeric] expected
      # @param [Numeric] min
      #
      # @raise [ArgumentError]
      #
      # @api private
      def check_greater(expected, min)
        unless expected > min
          raise ArgumentError,
                "Repeat value: #{expected} needs to be greater than #{min}"
        end
      end
      module_function :check_greater
    end # ExecutionTime
  end # Perf
end # Benchmark
