# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for any pending or skipped examples.
      #
      # @example
      #   # bad
      #   describe MyClass do
      #     it "should be true"
      #   end
      #
      #   describe MyClass do
      #     it "should be true", skip: true do
      #       expect(1).to eq(2)
      #     end
      #   end
      #
      #   describe MyClass do
      #     it "should be true" do
      #       pending
      #     end
      #   end
      #
      #   describe MyClass do
      #     xit "should be true" do
      #     end
      #   end
      #
      #   # good
      #   describe MyClass do
      #   end
      class Pending < Cop
        MSG = 'Pending spec found.'

        PENDING = Examples::PENDING + Examples::SKIPPED + ExampleGroups::SKIPPED
        SKIPPABLE = ExampleGroups::GROUPS + Examples::EXAMPLES

        def_node_matcher :skippable?, SKIPPABLE.send_pattern

        def_node_matcher :skipped_in_metadata?, <<-PATTERN
          {
            (send _ _ <#skip_or_pending? ...>)
            (send _ _ ... (hash <(pair #skip_or_pending? { true str }) ...>))
          }
        PATTERN

        def_node_matcher :skip_or_pending?, '{(sym :skip) (sym :pending)}'
        def_node_matcher :pending_block?, PENDING.send_pattern

        def on_send(node)
          return unless pending_block?(node) || skipped?(node)

          add_offense(node)
        end

        private

        def skipped?(node)
          skippable?(node) && skipped_in_metadata?(node)
        end
      end
    end
  end
end
