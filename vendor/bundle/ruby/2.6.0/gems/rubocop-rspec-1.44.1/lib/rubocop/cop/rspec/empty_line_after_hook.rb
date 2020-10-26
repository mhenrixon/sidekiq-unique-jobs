# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after hook blocks.
      #
      # @example
      #   # bad
      #   before { do_something }
      #   it { does_something }
      #
      #   # bad
      #   after { do_something }
      #   it { does_something }
      #
      #   # bad
      #   around { |test| test.run }
      #   it { does_something }
      #
      #   # good
      #   before { do_something }
      #
      #   it { does_something }
      #
      #   # good
      #   after { do_something }
      #
      #   it { does_something }
      #
      #   # good
      #   around { |test| test.run }
      #
      #   it { does_something }
      #
      class EmptyLineAfterHook < Base
        extend AutoCorrector
        include RuboCop::RSpec::EmptyLineSeparation

        MSG = 'Add an empty line after `%<hook>s`.'

        def on_block(node)
          return unless hook?(node)

          missing_separating_line_offense(node) do |method|
            format(MSG, hook: method)
          end
        end
      end
    end
  end
end
