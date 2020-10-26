# coding: utf-8

module Guard
  class Reek
    # This class runs `reek` command, retrieves result and notifies.
    # An instance of this class is intended to invoke `reek` only once in its lifetime.
    class Runner
      attr_reader :notifier, :ui, :result

      def initialize(options)
        @cli = options[:cli]
        @all = options[:all] || '*'
        @notifier = options[:notifier] || Notifier
        @ui = options[:ui] || UI
      end

      # this class decides which files are run against reek
      class Paths
        def initialize(paths, all)
          @all = all
          @paths = paths
          @paths = [] if @paths.include?('.reek')
        end

        def to_s
          @paths.empty? ? 'all' : @paths.to_s
        end

        def to_ary
          if @paths.empty?
            Array(@all)
          else
            @paths
          end
        end
      end

      def run(paths = [])
        result = run_reek_cmd(paths)

        if result
          notifier.notify('Reek Results', title: 'Passed', image: :success)
        else
          notifier.notify('Reek Results', title: 'Failed', image: :failed)
        end
      end

      private

      def run_reek_cmd(paths)
        runner_paths = Paths.new(paths, @all)
        ui.info("Guard::Reek is running on #{runner_paths}")

        command = reek_cmd.concat(runner_paths)
        Kernel.system(command.join(' '))
      end

      def reek_cmd
        ['reek', @cli].compact
      end
    end
  end
end
