# frozen_string_literal: true

module SidekiqUniqueJobs
  class UniqueJobsError < ::RuntimeError
  end

  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class InvalidUniqueArguments < UniqueJobsError
    def initialize(given:, worker_class:, unique_args_method:)
      uniq_args_meth  = worker_class.method(unique_args_method)
      num_args        = uniq_args_meth.arity
      # source_location = uniq_args_meth.source_location

      super(
        "#{worker_class}#unique_args takes #{num_args} arguments, received #{given.inspect}"
      )
    end
  end

  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class Conflict < UniqueJobsError
    def initialize(item)
      super("Item with the key: #{item[UNIQUE_DIGEST_KEY]} is already scheduled or processing")
    end
  end

  # Error raised from {OnConflict::Raise}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class ScriptError < UniqueJobsError
    # Reformats errors raised by redis representing failures while executing
    # a lua script. The default errors have confusing messages and backtraces,
    # and a type of +RuntimeError+. This class improves the message and
    # modifies the backtrace to include the lua script itself in a reasonable
    # way.

    PATTERN  = /ERR Error (compiling|running) script \(.*?\): .*?:(\d+): (.*)/.freeze
    LIB_PATH = File.expand_path("..", __dir__)
    CONTEXT_LINE_NUMBER = 2

    attr_reader :error, :file, :content

    # Is this error one that should be reformatted?
    #
    # @param error [StandardError] the original error raised by redis
    # @return [Boolean] is this an error that should be reformatted?
    def self.intercepts?(error)
      error.message =~ PATTERN
    end

    # Initialize a new {LuaError} from an existing redis error, adjusting
    # the message and backtrace in the process.
    #
    # @param error [StandardError] the original error raised by redis
    # @param file [Pathname] full path to the lua file the error ocurred in
    # @param content [String] lua file content the error ocurred in
    def initialize(error, file, content)
      @error   = error
      @file    = file
      @content = content

      @error.message =~ PATTERN
      _stage = Regexp.last_match(1)
      line_number = Regexp.last_match(2)
      message = Regexp.last_match(3)
      error_context = generate_error_context(content, line_number.to_i)

      super("#{message}\n\n#{error_context}\n\n")
      set_backtrace(generate_backtrace(file, line_number))
    end

    private

    def generate_error_context(content, line_number)
      lines = content.lines.to_a
      beginning_line_number = [1, line_number - CONTEXT_LINE_NUMBER].max
      ending_line_number = [lines.count, line_number + CONTEXT_LINE_NUMBER].min
      line_number_width = ending_line_number.to_s.length

      (beginning_line_number..ending_line_number).map do |number|
        indicator = (number == line_number) ? "=>" : "  "
        formatted_number = format("%#{line_number_width}d", number)
        " #{indicator} #{formatted_number}: #{lines[number - 1]}"
      end.join.chomp
    end

    def generate_backtrace(file, line_number)
      pre_unique_jobs = backtrace_before_entering_unique_jobs(@error.backtrace)
      index_of_first_unique_jobs_line = (@error.backtrace.size - pre_unique_jobs.size - 1)
      pre_unique_jobs.unshift(@error.backtrace[index_of_first_unique_jobs_line])
      pre_unique_jobs.unshift("#{file}:#{line_number}")
      pre_unique_jobs
    end

    def backtrace_before_entering_unique_jobs(backtrace)
      backtrace.reverse.take_while { |line| !line_from_unique_jobs(line) }.reverse
    end

    def line_from_unique_jobs(line)
      line.split(":").first.include?(LIB_PATH)
    end
  end

  # Error raised from {OptionsWithFallback#lock_class}
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class UnknownLock < UniqueJobsError
  end
end
