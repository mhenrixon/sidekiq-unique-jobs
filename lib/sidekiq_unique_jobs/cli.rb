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

    desc "keys PATTERN", "list all unique keys and their expiry time"
    option :count, aliases: :c, type: :numeric, default: 1000, desc: "The max number of keys to return"
    def keys(pattern = "*")
      keys = Util.keys(pattern, options[:count])
      say "Found #{keys.size} keys matching '#{pattern}':"
      print_in_columns(keys.sort) if keys.any?
    end

    desc "del PATTERN", "deletes unique keys from redis by pattern"
    option :dry_run, aliases: :d, type: :boolean, desc: "set to false to perform deletion"
    option :count, aliases: :c, type: :numeric, default: 1000, desc: "The max number of keys to return"
    def del(pattern)
      max_count = options[:count]
      if options[:dry_run]
        keys = Util.keys(pattern, max_count)
        say "Would delete #{keys.size} keys matching '#{pattern}'"
      else
        deleted_count = Util.del(pattern, max_count)
        say "Deleted #{deleted_count} keys matching '#{pattern}'"
      end
    end

    desc "console", "drop into a console with easy access to helper methods"
    def console
      say "Use `keys '*', 1000 to display the first 1000 unique keys matching '*'"
      say "Use `del '*', 1000, true (default) to see how many keys would be deleted for the pattern '*'"
      say "Use `del '*', 1000, false to delete the first 1000 keys matching '*'"
      Object.include SidekiqUniqueJobs::Util
      console_class.start
    end

    no_commands do
      def console_class
        require "pry"
        Pry
      rescue LoadError
        require "irb"
        IRB
      end
    end
  end
end
