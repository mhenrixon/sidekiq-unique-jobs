# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if examples are focused.
      #
      # @example
      #   # bad
      #   describe MyClass, focus: true do
      #   end
      #
      #   describe MyClass, :focus do
      #   end
      #
      #   fdescribe MyClass do
      #   end
      #
      #   # good
      #   describe MyClass do
      #   end
      class Focus < Cop
        MSG = 'Focused spec found.'

        focusable =
          ExampleGroups::GROUPS  +
          ExampleGroups::SKIPPED +
          Examples::EXAMPLES     +
          Examples::SKIPPED      +
          Examples::PENDING

        focused = ExampleGroups::FOCUSED + Examples::FOCUSED

        FOCUSABLE_SELECTORS = focusable.node_pattern_union

        def_node_matcher :metadata, <<-PATTERN
          {(send #{RSPEC} #{FOCUSABLE_SELECTORS} <$(sym :focus) ...>)
           (send #{RSPEC} #{FOCUSABLE_SELECTORS} ... (hash <$(pair (sym :focus) true) ...>))}
        PATTERN

        def_node_matcher :focused_block?, focused.send_pattern

        def on_send(node)
          focus_metadata(node) do |focus|
            add_offense(focus)
          end
        end

        private

        def focus_metadata(node, &block)
          yield(node) if focused_block?(node)

          metadata(node, &block)
        end
      end
    end
  end
end
