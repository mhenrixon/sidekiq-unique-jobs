# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.7, `UnboundMethod#bind_call` has been added.
      #
      # This cop identifies places where `bind(obj).call(args, ...)`
      # can be replaced by `bind_call(obj, args, ...)`.
      #
      # The `bind_call(obj, args, ...)` method is faster than
      # `bind(obj).call(args, ...)`.
      #
      # @example
      #   # bad
      #   umethod.bind(obj).call(foo, bar)
      #   umethod.bind(obj).(foo, bar)
      #
      #   # good
      #   umethod.bind_call(obj, foo, bar)
      #
      class BindCall < Cop
        include RangeHelp
        extend TargetRubyVersion

        minimum_target_ruby_version 2.7

        MSG = 'Use `bind_call(%<bind_arg>s%<comma>s%<call_args>s)` ' \
              'instead of `bind(%<bind_arg>s).call(%<call_args>s)`.'

        def_node_matcher :bind_with_call_method?, <<~PATTERN
          (send
            $(send
              (send nil? _) :bind
              $(...)) :call
            $...)
        PATTERN

        def on_send(node)
          bind_with_call_method?(node) do |receiver, bind_arg, call_args_node|
            range = correction_range(receiver, node)

            call_args = build_call_args(call_args_node)

            message = message(bind_arg.source, call_args)

            add_offense(node, location: range, message: message)
          end
        end

        def autocorrect(node)
          receiver, bind_arg, call_args_node = bind_with_call_method?(node)

          range = correction_range(receiver, node)

          call_args = build_call_args(call_args_node)
          call_args = ", #{call_args}" unless call_args.empty?

          replacement_method = "bind_call(#{bind_arg.source}#{call_args})"

          lambda do |corrector|
            corrector.replace(range, replacement_method)
          end
        end

        private

        def message(bind_arg, call_args)
          comma = call_args.empty? ? '' : ', '

          format(MSG, bind_arg: bind_arg, comma: comma, call_args: call_args)
        end

        def correction_range(receiver, node)
          location_of_bind = receiver.loc.selector.begin_pos
          location_of_call = node.loc.end.end_pos

          range_between(location_of_bind, location_of_call)
        end

        def build_call_args(call_args_node)
          call_args_node.map(&:source).join(', ')
        end
      end
    end
  end
end
