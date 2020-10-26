# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      #  Checks for empty before and after hooks.
      #
      # @example
      #   # bad
      #   before {}
      #   after do; end
      #   before(:all) do
      #   end
      #   after(:all) { }
      #
      #   # good
      #   before { create_users }
      #   after do
      #     cleanup_users
      #   end
      #   before(:all) do
      #     create_feed
      #   end
      #   after(:all) { cleanup_feed }
      class EmptyHook < Base
        extend AutoCorrector
        include RuboCop::Cop::RangeHelp

        MSG = 'Empty hook detected.'

        def_node_matcher :empty_hook?, <<~PATTERN
          (block $#{Hooks::ALL.send_pattern} _ nil?)
        PATTERN

        def on_block(node)
          empty_hook?(node) do |hook|
            add_offense(hook) do |corrector|
              range = range_with_surrounding_space(range: node.loc.expression)
              corrector.remove(range)
            end
          end
        end
      end
    end
  end
end
