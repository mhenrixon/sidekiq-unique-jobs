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
      class Focus < Base
        MSG = 'Focused spec found.'

        focused = ExampleGroups::FOCUSED + Examples::FOCUSED

        def_node_matcher :focusable_selector?,
                         (ExampleGroups::GROUPS + ExampleGroups::SKIPPED +
                          Examples::EXAMPLES + Examples::SKIPPED +
                          Examples::PENDING).node_pattern_union

        def_node_matcher :metadata, <<-PATTERN
          {(send #rspec? #focusable_selector? <$(sym :focus) ...>)
           (send #rspec? #focusable_selector? ... (hash <$(pair (sym :focus) true) ...>))}
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
