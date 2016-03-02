require 'thor'

module SidekiqUniqueJobs
  class Cli < Thor
    desc 'keys PATTERN', 'list all unique keys and their expiry time'
    option :count, aliases: :c, type: :numeric, default: 1000, desc: 'The max number of keys to return'
    def keys(pattern)
      Util.keys(pattern, options[:count])
    end

    desc 'del PATTERN', 'deletes unique keys from redis by pattern'
    option :dry_run, aliases: :d, type: :boolean, desc: 'set to false to perform deletion'
    option :count, aliases: :c, type: :numeric, default: 1000, desc: 'The max number of keys to return'
    def del(pattern)
      Util.del(pattern, options[:count], options[:dry_run])
    end

    desc 'console', 'drop into a console with easy access to helper methods'
    def console
      puts "Use `keys '*', 1000 to display the first 1000 unique keys matching '*'"
      puts "Use `del '*', 1000, true (default) to see how many keys would be deleted for the pattern '*'"
      puts "Use `del '*', 1000, false to delete the first 1000 keys matching '*'"
      Object.include SidekiqUniqueJobs::Util
      console_class.start
    end

    private

    def console_class
      require 'pry'
      Pry
    rescue LoadError
      require 'irb'
      IRB
    end
  end
end
