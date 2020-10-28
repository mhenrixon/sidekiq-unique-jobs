# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Enforce that subject is the first definition in the test.
      #
      # @example
      #   # bad
      #     let(:params) { blah }
      #     subject { described_class.new(params) }
      #
      #     before { do_something }
      #     subject { described_class.new(params) }
      #
      #     it { expect_something }
      #     subject { described_class.new(params) }
      #     it { expect_something_else }
      #
      #
      #   # good
      #     subject { described_class.new(params) }
      #     let(:params) { blah }
      #
      #   # good
      #     subject { described_class.new(params) }
      #     before { do_something }
      #
      #   # good
      #     subject { described_class.new(params) }
      #     it { expect_something }
      #     it { expect_something_else }
      #
      class LeadingSubject < Cop
        MSG = 'Declare `subject` above any other `%<offending>s` declarations.'

        def on_block(node)
          return unless subject?(node) && !in_spec_block?(node)

          check_previous_nodes(node)
        end

        def check_previous_nodes(node)
          node.parent.each_child_node do |sibling|
            if offending?(sibling)
              add_offense(
                node,
                message: format(MSG, offending: sibling.method_name)
              )
            end

            break if offending?(sibling) || sibling.equal?(node)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            first_node = find_first_offending_node(node)
            RuboCop::RSpec::Corrector::MoveNode.new(
              node, corrector, processed_source
            ).move_before(first_node)
          end
        end

        private

        def offending?(node)
          let?(node) || hook?(node) || example?(node)
        end

        def find_first_offending_node(node)
          node.parent.children.find { |sibling| offending?(sibling) }
        end

        def in_spec_block?(node)
          node.each_ancestor(:block).any? do |ancestor|
            example?(ancestor)
          end
        end
      end
    end
  end
end
