# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after subject block.
      #
      # @example
      #   # bad
      #   subject(:obj) { described_class }
      #   let(:foo) { bar }
      #
      #   # good
      #   subject(:obj) { described_class }
      #
      #   let(:foo) { bar }
      class EmptyLineAfterSubject < Base
        extend AutoCorrector
        include RuboCop::RSpec::EmptyLineSeparation

        MSG = 'Add an empty line after `%<subject>s`.'

        def on_block(node)
          return unless subject?(node) && !in_spec_block?(node)

          missing_separating_line_offense(node) do |method|
            format(MSG, subject: method)
          end
        end

        private

        def in_spec_block?(node)
          node.each_ancestor(:block).any? do |ancestor|
            Examples::ALL.include?(ancestor.method_name)
          end
        end
      end
    end
  end
end
