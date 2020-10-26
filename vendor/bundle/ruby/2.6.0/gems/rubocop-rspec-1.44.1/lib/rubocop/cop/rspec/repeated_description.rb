# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for repeated description strings in example groups.
      #
      # @example
      #
      #     # bad
      #     RSpec.describe User do
      #       it 'is valid' do
      #         # ...
      #       end
      #
      #       it 'is valid' do
      #         # ...
      #       end
      #     end
      #
      #     # good
      #     RSpec.describe User do
      #       it 'is valid when first and last name are present' do
      #         # ...
      #       end
      #
      #       it 'is valid when last name only is present' do
      #         # ...
      #       end
      #     end
      #
      #     # good
      #     RSpec.describe User do
      #       it 'is valid' do
      #         # ...
      #       end
      #
      #       it 'is valid', :flag do
      #         # ...
      #       end
      #     end
      #
      class RepeatedDescription < Base
        MSG = "Don't repeat descriptions within an example group."

        def on_block(node)
          return unless example_group?(node)

          repeated_descriptions(node).each do |repeated_description|
            add_offense(repeated_description)
          end
        end

        private

        # Select examples in the current scope with repeated description strings
        def repeated_descriptions(node)
          grouped_examples =
            RuboCop::RSpec::ExampleGroup.new(node)
              .examples
              .group_by { |example| example_signature(example) }

          grouped_examples
            .select { |signatures, group| signatures.any? && group.size > 1 }
            .values
            .flatten
            .map(&:definition)
        end

        def example_signature(example)
          [example.metadata, example.doc_string]
        end
      end
    end
  end
end
