# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Avoid opening modules and defining specs within them.
      #
      # @example
      #   # bad
      #   module MyModule
      #     RSpec.describe MyClass do
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe MyModule::MyClass do
      #     # ...
      #   end
      #
      # @see https://github.com/rubocop-hq/rubocop-rspec/issues/735
      class DescribedClassModuleWrapping < Cop
        MSG = 'Avoid opening modules and defining specs within them.'

        def_node_search :find_rspec_blocks,
                        ExampleGroups::ALL.block_pattern

        def on_module(node)
          find_rspec_blocks(node) do
            add_offense(node)
          end
        end
      end
    end
  end
end
