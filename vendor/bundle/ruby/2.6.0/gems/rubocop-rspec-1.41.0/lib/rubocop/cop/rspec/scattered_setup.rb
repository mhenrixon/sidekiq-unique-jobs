# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for setup scattered across multiple hooks in an example group.
      #
      # Unify `before`, `after`, and `around` hooks when possible.
      #
      # @example
      #   # bad
      #   describe Foo do
      #     before { setup1 }
      #     before { setup2 }
      #   end
      #
      #   # good
      #   describe Foo do
      #     before do
      #       setup1
      #       setup2
      #     end
      #   end
      #
      class ScatteredSetup < Cop
        MSG = 'Do not define multiple `%<hook_name>s` hooks in the same '\
              'example group (also defined on %<lines>s).'

        def on_block(node)
          return unless example_group?(node)

          repeated_hooks(node).each do |occurrences|
            lines = occurrences.map(&:first_line)

            occurrences.each do |occurrence|
              lines_except_current = lines - [occurrence.first_line]
              message = format(MSG, hook_name: occurrences.first.method_name,
                               lines: lines_msg(lines_except_current))
              add_offense(occurrence, message: message)
            end
          end
        end

        def repeated_hooks(node)
          hooks = RuboCop::RSpec::ExampleGroup.new(node)
            .hooks
            .select(&:knowable_scope?)
            .group_by { |hook| [hook.name, hook.scope, hook.metadata] }
            .values
            .reject(&:one?)

          hooks.map do |hook|
            hook.map(&:to_node)
          end
        end

        def lines_msg(numbers)
          if numbers.size == 1
            "line #{numbers.first}"
          else
            "lines #{numbers.join(', ')}"
          end
        end
      end
    end
  end
end
