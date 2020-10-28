# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that `all` matcher is used instead of iterating over an array.
      #
      # @example
      #   # bad
      #   it 'validates users' do
      #     [user1, user2, user3].each { |user| expect(user).to be_valid }
      #   end
      #
      #   # good
      #   it 'validates users' do
      #     expect([user1, user2, user3]).to all(be_valid)
      #   end
      class IteratedExpectation < Cop
        MSG = 'Prefer using the `all` matcher instead ' \
                  'of iterating over an array.'

        def_node_matcher :each?, <<-PATTERN
          (block
            (send ... :each)
            (args (arg $_))
            $(...)
          )
        PATTERN

        def_node_matcher :expectation?, <<-PATTERN
          (send (send nil? :expect (lvar %)) :to ...)
        PATTERN

        def on_block(node)
          each?(node) do |arg, body|
            if single_expectation?(body, arg) || only_expectations?(body, arg)
              add_offense(node.send_node)
            end
          end
        end

        private

        def single_expectation?(body, arg)
          expectation?(body, arg)
        end

        def only_expectations?(body, arg)
          body.each_child_node.all? { |child| expectation?(child, arg) }
        end
      end
    end
  end
end
