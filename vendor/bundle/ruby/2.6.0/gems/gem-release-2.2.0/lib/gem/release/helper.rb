require 'forwardable'

module Gem
  module Release
    module Helper
      extend Forwardable
      def_delegators :context, :gem, :git, :ui

      def run(cmd)
        return true if send(cmd)
      end

      def cmd(cmd, *args)
        if cmd.is_a?(Symbol)
          info cmd, *args
          cmd = self.class::CMDS[cmd] % args
        end
        cmd = cmd.strip
        ui.cmd cmd
        result = pretend? ? true : context.run(cmd)
        abort "The command `#{cmd}` was unsuccessful." unless result
      end

      def gem_cmd(cmd, *args)
        info cmd, *args if cmd.is_a?(Symbol)
        ui.cmd "gem #{cmd} #{args.join(' ')}"
        pretend? ? true : context.gem_cmd(cmd, *args)
      end

      %w(announce notice info warn error).each do |level|
        define_method(level) do |msg, *args|
          ui.send(level, msg, args, self.class::MSGS)
        end
      end

      def abort(msg, *args)
        processed_msg = if msg.is_a?(Symbol)
          self.class::MSGS.fetch(msg) % args
        else
          msg
        end
        context.abort("#{processed_msg} Aborting.")
      end
    end
  end
end
