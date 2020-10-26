# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that the second argument to `describe` specifies a method.
      #
      # @example
      #   # bad
      #   describe MyClass, 'do something' do
      #   end
      #
      #   # good
      #   describe MyClass, '#my_instance_method' do
      #   end
      #
      #   describe MyClass, '.my_class_method' do
      #   end
      class DescribeMethod < Base
        include RuboCop::RSpec::TopLevelGroup

        MSG = 'The second argument to describe should be the method '\
              "being tested. '#instance' or '.class'."

        def_node_matcher :second_argument, <<~PATTERN
          (block
            (send #rspec? :describe _first_argument $(str _) ...) ...
          )
        PATTERN

        def on_top_level_group(node)
          second_argument = second_argument(node)

          return unless second_argument
          return if second_argument.str_content.start_with?('#', '.')

          add_offense(second_argument)
        end
      end
    end
  end
end
