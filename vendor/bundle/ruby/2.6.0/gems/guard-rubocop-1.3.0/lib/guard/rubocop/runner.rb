require 'json'

module Guard
  class RuboCop
    # This class runs `rubocop` command, retrieves result and notifies.
    # An instance of this class is intended to invoke `rubocop` only once in its lifetime.
    class Runner
      def initialize(options)
        @options = options
      end

      def run(paths = [])
        command = build_command(paths)
        passed = system(*command)

        case @options[:notification]
        when :failed
          notify(passed) unless passed
        when true
          notify(passed)
        end

        open_launchy_if_needed

        passed
      end

      def build_command(paths)
        command = ['rubocop']

        if should_add_default_formatter_for_console?
          command.concat(%w[--format progress]) # Keep default formatter for console.
        end

        command.concat(['--format', 'json', '--out', json_file_path])
        command << '--force-exclusion'
        command.concat(args_specified_by_user)
        command.concat(paths)
      end

      def should_add_default_formatter_for_console?
        !@options[:hide_stdout] && !include_formatter_for_console?(args_specified_by_user)
      end

      def args_specified_by_user
        @args_specified_by_user ||= begin
          args = @options[:cli]
          case args
          when Array    then args
          when String   then args.shellsplit
          when NilClass then []
          else raise ArgumentError, ':cli option must be either an array or string'
          end
        end
      end

      def include_formatter_for_console?(cli_args)
        index = -1
        formatter_args = cli_args.group_by do |arg|
          index += 1 if arg == '--format' || arg.start_with?('-f')
          index
        end
        formatter_args.delete(-1)

        formatter_args.each_value.any? do |args|
          args.none? { |a| a == '--out' || a.start_with?('-o') }
        end
      end

      def json_file_path
        @json_file_path ||= begin
          # Just generate random tempfile path.
          basename = self.class.name.downcase.gsub('::', '_')
          tempfile = Tempfile.new(basename)
          tempfile.close
          tempfile.path
        end
      end

      def result
        @result ||= begin
          File.open(json_file_path) do |file|
            # Rubinius 2.0.0.rc1 does not support `JSON.load` with 3 args.
            JSON.parse(file.read, symbolize_names: true)
          end
        end
      end

      def notify(passed)
        image = passed ? :success : :failed
        Notifier.notify(summary_text, title: 'RuboCop results', image: image)
      end

      def summary_text
        summary = result[:summary]

        text = pluralize(summary[:inspected_file_count], 'file')
        text << ' inspected, '

        offense_count = summary[:offense_count] || summary[:offence_count]
        text << pluralize(offense_count, 'offense', no_for_zero: true)
        text << ' detected'
      end

      def failed_paths
        failed_files = result[:files].reject do |file|
          offenses = file[:offenses] || file[:offences]
          offenses.empty?
        end
        failed_files.map do |file|
          file[:path]
        end
      end

      def pluralize(number, thing, options = {})
        text = ''

        if number.zero? && options[:no_for_zero]
          text = 'no'
        else
          text << number.to_s
        end

        text << " #{thing}"
        text << 's' unless number == 1

        text
      end

      def open_launchy_if_needed
        return unless (output_path = @options[:launchy])
        return unless File.exist?(output_path)
        require 'launchy'
        ::Launchy.open(output_path)
      end
    end
  end
end
