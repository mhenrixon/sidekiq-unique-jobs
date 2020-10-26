# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop checks for redundant `String#chars`.
      #
      # @example
      #   # bad
      #   str.chars[0..2]
      #   str.chars.slice(0..2)
      #
      #   # good
      #   str[0..2].chars
      #
      #   # bad
      #   str.chars.first
      #   str.chars.first(2)
      #   str.chars.last
      #   str.chars.last(2)
      #
      #   # good
      #   str[0]
      #   str[0...2].chars
      #   str[-1]
      #   str[-2..-1].chars
      #
      #   # bad
      #   str.chars.take(2)
      #   str.chars.drop(2)
      #   str.chars.length
      #   str.chars.size
      #   str.chars.empty?
      #
      #   # good
      #   str[0...2].chars
      #   str[2..-1].chars
      #   str.length
      #   str.size
      #   str.empty?
      #
      class RedundantStringChars < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of `%<bad_method>s`.'
        REPLACEABLE_METHODS = %i[[] slice first last take drop length size empty?].freeze

        def_node_matcher :redundant_chars_call?, <<~PATTERN
          (send $(send _ :chars) $#replaceable_method? $...)
        PATTERN

        def on_send(node)
          return unless (receiver, method, args = redundant_chars_call?(node))

          range = offense_range(receiver, node)
          message = build_message(method, args)

          add_offense(range, message: message) do |corrector|
            range = correction_range(receiver, node)
            replacement = build_good_method(method, args)

            corrector.replace(range, replacement)
          end
        end

        private

        def replaceable_method?(method_name)
          REPLACEABLE_METHODS.include?(method_name)
        end

        def offense_range(receiver, node)
          range_between(receiver.loc.selector.begin_pos, node.loc.expression.end_pos)
        end

        def correction_range(receiver, node)
          range_between(receiver.loc.dot.begin_pos, node.loc.expression.end_pos)
        end

        def build_message(method, args)
          good_method = build_good_method(method, args)
          bad_method = build_bad_method(method, args)
          format(MSG, good_method: good_method, bad_method: bad_method)
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        def build_good_method(method, args)
          case method
          when :[], :slice
            "[#{build_call_args(args)}].chars"
          when :first
            if args.any?
              "[0...#{args.first.source}].chars"
            else
              '[0]'
            end
          when :last
            if args.any?
              "[-#{args.first.source}..-1].chars"
            else
              '[-1]'
            end
          when :take
            "[0...#{args.first.source}].chars"
          when :drop
            "[#{args.first.source}..-1].chars"
          else
            ".#{method}"
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

        def build_bad_method(method, args)
          case method
          when :[]
            "chars[#{build_call_args(args)}]"
          else
            if args.any?
              "chars.#{method}(#{build_call_args(args)})"
            else
              "chars.#{method}"
            end
          end
        end

        def build_call_args(call_args_node)
          call_args_node.map(&:source).join(', ')
        end
      end
    end
  end
end
