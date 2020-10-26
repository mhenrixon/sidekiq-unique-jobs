require 'gem/release/cmds/runner'

module Gem
  module Release
    module GemCommand
      class Setup < Struct.new(:name, :cmd)
        def run
          cmd.summary      = const.summary
          cmd.description  = const.description
          cmd.usage        = usage
          cmd.arguments    = arguments
          cmd.defaults_str = ''

          opts.each do |args|
            cmd.add_option(*args.first) do |*a|
              cmd.instance_exec(*a, &args.last)
            end
          end
        end

        def opts
          const.opts + Cmds::Base.opts
        end

        def const
          Cmds[name] || raise("Unknown command #{name}")
        end

        def usage
          args = const.args.map(&:first)
          [:gem, name, args.map { |arg| "[#{arg}]" }.join(' ')].join(' ')
        end

        def arguments
          arg  = const.args.map(&:first).max_by(&:size)
          args = const.args.map { |name, summary| [name.to_s.ljust(arg.size), summary] }
          args.map { |pair| pair.join(' - ') }.join("\n")
        end
      end

      def self.included(const)
        const.singleton_class.send(:attr_accessor, :cmd)
        const.send(:alias_method, :opts, :options)
      end

      attr_accessor :arguments, :usage, :defaults_str, :description

      def initialize
        super(cmd)
        Setup.new(cmd, self).run
      end

      def execute
        Cmds::Runner.new(cmd, opts.delete(:args), opts).run
      rescue Abort => ex
        abort(ex.message)
      end

      def cmd
        self.class.cmd
      end
    end
  end
end

