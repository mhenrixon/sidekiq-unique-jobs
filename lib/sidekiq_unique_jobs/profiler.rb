# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class MethodProfiler provides method level profiling
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class Profiler
    def self.patch(klass, methods, name) # rubocop:disable Metrics/MethodLength
      patches = methods.map do |method_name|
        <<~RUBY
          unless defined?(#{method_name}__mp_unpatched)
            alias_method :#{method_name}__mp_unpatched, :#{method_name}
            def #{method_name}(*args, &blk)
              unless prof = Thread.current[:_method_profiler]
                return #{method_name}__mp_unpatched(*args, &blk)
              end
              begin
                start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
                #{method_name}__mp_unpatched(*args, &blk)
              ensure
                data = (prof[:#{name}] ||= {duration: 0.0, calls: 0})
                data[:duration] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
                data[:calls] += 1
              end
            end
          end
        RUBY
      end.join("\n")

      klass.class_eval patches
    end

    def self.start
      Thread.current[:_method_profiler] = {
        __start: Process.clock_gettime(Process::CLOCK_MONOTONIC),
      }
    end

    def self.stop
      finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return unless (data = Thread.current[:_method_profiler])

      Thread.current[:_method_profiler] = nil
      start = data.delete(:__start)
      data[:total_duration] = finish - start
      data
    end
  end
end
