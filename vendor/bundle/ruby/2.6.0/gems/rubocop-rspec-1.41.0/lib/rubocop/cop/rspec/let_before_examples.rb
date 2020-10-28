# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for `let` definitions that come after an example.
      #
      # @example
      #   # Bad
      #   let(:foo) { bar }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   let(:some) { other }
      #
      #   it 'checks what some does' do
      #     expect(some).to be
      #   end
      #
      #   # Good
      #   let(:foo) { bar }
      #   let(:some) { other }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   it 'checks what some does' do
      #     expect(some).to be
      #   end
      class LetBeforeExamples < Cop
        MSG = 'Move `let` before the examples in the group.'

        def_node_matcher :example_or_group?, <<-PATTERN
          {
            #{(Examples::ALL + ExampleGroups::ALL).block_pattern}
            #{Includes::EXAMPLES.send_pattern}
          }
        PATTERN

        def on_block(node)
          return unless example_group_with_body?(node)

          check_let_declarations(node.body) if multiline_block?(node.body)
        end

        def autocorrect(node)
          lambda do |corrector|
            first_example = find_first_example(node.parent)
            RuboCop::RSpec::Corrector::MoveNode.new(
              node, corrector, processed_source
            ).move_before(first_example)
          end
        end

        private

        def multiline_block?(block)
          block.begin_type?
        end

        def check_let_declarations(node)
          first_example = find_first_example(node)
          return unless first_example

          node.each_child_node do |child|
            next if child.sibling_index < first_example.sibling_index

            add_offense(child) if let?(child)
          end
        end

        def find_first_example(node)
          node.children.find { |sibling| example_or_group?(sibling) }
        end
      end
    end
  end
end
