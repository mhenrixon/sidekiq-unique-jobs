# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for usage of implicit subject (`is_expected` / `should`).
      #
      # This cop can be configured using the `EnforcedStyle` option
      #
      # @example `EnforcedStyle: single_line_only`
      #   # bad
      #   it do
      #     is_expected.to be_truthy
      #   end
      #
      #   # good
      #   it { is_expected.to be_truthy }
      #   it do
      #     expect(subject).to be_truthy
      #   end
      #
      # @example `EnforcedStyle: disallow`
      #   # bad
      #   it { is_expected.to be_truthy }
      #
      #   # good
      #   it { expect(subject).to be_truthy }
      #
      class ImplicitSubject < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG = "Don't use implicit subject."

        def_node_matcher :implicit_subject?, <<-PATTERN
          (send nil? {:should :should_not :is_expected} ...)
        PATTERN

        def on_send(node)
          return unless implicit_subject?(node)
          return if valid_usage?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          replacement = 'expect(subject)'
          case node.method_name
          when :should
            replacement += '.to'
          when :should_not
            replacement += '.not_to'
          end

          corrector.replace(node.loc.selector, replacement)
        end

        def valid_usage?(node)
          example = node.ancestors.find { |parent| example?(parent) }
          return false if example.nil?

          example.method?(:its) || allowed_by_style?(example)
        end

        def allowed_by_style?(example)
          case style
          when :single_line_only
            example.single_line?
          when :single_statement_only
            !example.body.begin_type?
          else
            false
          end
        end
      end
    end
  end
end
