# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for before/around/after hooks that come after an example.
      #
      # @example
      #   # Bad
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   before { prepare }
      #   after { clean_up }
      #
      #   # Good
      #   before { prepare }
      #   after { clean_up }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      class HooksBeforeExamples < Cop
        MSG = 'Move `%<hook>s` above the examples in the group.'

        def_node_matcher :example_or_group?, <<-PATTERN
          {
            #{(Examples::ALL + ExampleGroups::ALL).block_pattern}
            #{Includes::EXAMPLES.send_pattern}
          }
        PATTERN

        def on_block(node)
          return unless example_group_with_body?(node)

          check_hooks(node.body) if multiline_block?(node.body)
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

        def check_hooks(node)
          first_example = find_first_example(node)
          return unless first_example

          node.each_child_node do |child|
            next if child.sibling_index < first_example.sibling_index
            next unless hook?(child)

            add_offense(
              child,
              message: format(MSG, hook: child.method_name)
            )
          end
        end

        def find_first_example(node)
          node.children.find { |sibling| example_or_group?(sibling) }
        end
      end
    end
  end
end
