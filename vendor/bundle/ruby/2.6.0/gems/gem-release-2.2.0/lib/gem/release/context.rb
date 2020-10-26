require 'gem/release/context/gem'
require 'gem/release/context/git'
require 'gem/release/context/paths'
require 'gem/release/context/ui'

module Gem
  module Release
    class Context
      attr_accessor :config, :gem, :git, :ui

      def initialize(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        name = args.shift
        @config = Config.new
        @gem    = Gem.new(name || File.basename(Dir.pwd))
        @git    = Git.new
        @ui     = Ui.new(opts)
      end

      def run(cmd)
        system(cmd)
      end

      def gem_cmd(cmd, *args)
        ::Gem::Commands.const_get("#{cmd.to_s.capitalize}Command").new.invoke(*args.flatten)
        # TODO what's with the return value? maybe add our own abstraction that can check the result?
        true
      end

      def in_dirs(args, opts, &block)
        Paths::ByNames.new(args, opts).in_dirs(&block)
      end

      def in_gem_dirs(args, opts, &block)
        Paths::ByGemspecs.new(args, opts).in_dirs(&block)
      end

      def abort(str)
        ui.error(str)
        exit 1
      end
    end
  end
end
