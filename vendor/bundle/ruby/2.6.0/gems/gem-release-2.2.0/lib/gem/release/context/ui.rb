module Gem
  module Release
    class Context
      module Ui
        class << self
          def new(opts)
            const = Quiet if opts[:quiet]
            const ||= Tty if $stdout.tty?
            const ||= Pipe
            const.new(opts)
          end
        end

        class Base < Struct.new(:opts)
          attr_writer :stdout

          def stdout
            @stdout || $stdout
          end

          def puts(*str)
            stdout.puts(*str)
          end
        end

        class Pipe < Base
          %i(announce info notice warn error).each do |name|
            define_method (name) do |msg, args = nil, _ = nil|
              puts format_msg(msg, args)
            end
          end

          %i(success cmd).each do |name|
            define_method (name) { |*| }
          end

          private

            def format_msg(msg, args)
              msg = [msg, args].flatten.map(&:to_s)
              msg = msg.map { |str| quote_spaced(str) }
              msg.join(' ').strip
            end

            def quote_spaced(str)
              str.include?(' ') ? %("#{str}") : str
            end
        end

        class Quiet < Base
          %i(announce info notice warn error success cmd).each do |name|
            define_method (name) { |*| }
          end
        end

        module Colors
          COLORS = {
            red:    "\e[31m",
            green:  "\e[32m",
            yellow: "\e[33m",
            blue:   "\e[34m",
            gray:   "\e[37m",
            reset:  "\e[0m"
          }.freeze

          def colored(color, str)
            [COLORS[color], str, COLORS[:reset]].join
          end
        end

        class Tty < Base
          include Colors

          def announce(msg, args = [], msgs = [])
            msg = format_msg(msg, args, msgs)
            puts colored(:green, with_spacing(msg, true))
          end

          def info(msg, args = [], msgs = [])
            msg = format_msg(msg, args, msgs)
            puts colored(:blue, with_spacing(msg, true))
          end

          def notice(msg, args = [], msgs = [])
            msg = format_msg(msg, args, msgs)
            puts colored(:gray, with_spacing(msg, false))
          end

          def warn(msg, args = [], msgs = [])
            msg = format_msg(msg, args, msgs)
            puts colored(:yellow, with_spacing(msg, false))
          end

          def error(msg, args = [], msgs = [])
            msg = format_msg(msg, args, msgs)
            puts colored(:red, with_spacing(msg, true))
          end

          def success(msg)
            announce(msg)
            puts
          end

          def cmd(msg)
            notice("$ #{msg}")
          end

          private

            def colored(color, str)
              opts[:color] ? super : str
            end

            def format_msg(msg, args, msgs)
              msg = msgs[msg] % args if msg.is_a?(Symbol)
              msg.strip
            end

            def with_spacing(str, space)
              str = "\n#{str}" if space && !@last
              @last = space
              str
            end
        end
      end
    end
  end
end
