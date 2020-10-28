# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop is used to identify usages of `reverse.each` and
      # change them to use `reverse_each` instead.
      #
      # @example
      #   # bad
      #   [].reverse.each
      #
      #   # good
      #   [].reverse_each
      class ReverseEach < Cop
        include RangeHelp

        MSG = 'Use `reverse_each` instead of `reverse.each`.'
        UNDERSCORE = '_'

        def_node_matcher :reverse_each?, <<~MATCHER
          (send $(send _ :reverse) :each)
        MATCHER

        def on_send(node)
          reverse_each?(node) do |receiver|
            location_of_reverse = receiver.loc.selector.begin_pos
            end_location = node.loc.selector.end_pos

            range = range_between(location_of_reverse, end_location)

            add_offense(node, location: range)
          end
        end

        def autocorrect(node)
          range = range_between(node.loc.dot.begin_pos, node.loc.selector.begin_pos)
          ->(corrector) { corrector.replace(range, UNDERSCORE) }
        end
      end
    end
  end
end
