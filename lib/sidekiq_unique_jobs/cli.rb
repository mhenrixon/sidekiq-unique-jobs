# frozen_string_literal: true

require "thor"

module SidekiqUniqueJobs
  #
  # Command line interface for unique jobs
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class Cli < Thor
    def self.banner(command, _namespace = nil, _subcommand = false)
      "jobs #{@package_name} #{command.usage}"
    end

    desc "list PATTERN", "list all unique digests and their expiry time"
    option :count, aliases: :c, type: :numeric, default: 1000, desc: "The max number of digests to return"
    def list(pattern = "*")
      digests = SidekiqUniqueJobs::Digests.new.entries(pattern: pattern, count: options[:count])
      say "Found #{digests.size} digests matching '#{pattern}':"
      print_in_columns(digests.sort) if digests.any?
    end

    desc "del PATTERN", "deletes unique digests from redis by pattern"
    option :dry_run, aliases: :d, type: :boolean, desc: "set to false to perform deletion"
    option :count, aliases: :c, type: :numeric, default: 1000, desc: "The max number of digests to return"
    def del(pattern)
      max_count = options[:count]
      if options[:dry_run]
        digests = SidekiqUniqueJobs::Digests.new.entries(pattern: pattern, count: max_count)
        say "Would delete #{digests.size} digests matching '#{pattern}'"
      else
        deleted_count = SidekiqUniqueJobs::Digests.new.del(pattern: pattern, count: max_count)
        say "Deleted #{deleted_count} digests matching '#{pattern}'"
      end
    end

    desc "console", "drop into a console with easy access to helper methods"
    def console
      say "Use `list '*', 1000 to display the first 1000 unique digests matching '*'"
      say "Use `del '*', 1000, true (default) to see how many digests would be deleted for the pattern '*'"
      say "Use `del '*', 1000, false to delete the first 1000 digests matching '*'"

      # Object.include SidekiqUniqueJobs::Api
      console_class.start
    end

    no_commands do
      def console_class
        require "pry"
        Pry
      rescue NameError, LoadError
        require "irb"
        IRB
      end
    end
  end
end
