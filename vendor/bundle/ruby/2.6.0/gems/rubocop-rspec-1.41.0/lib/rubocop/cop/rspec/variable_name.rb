# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that memoized helper names use the configured style.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   let(:userName) { 'Adam' }
      #   subject(:userName) { 'Adam' }
      #
      #   # good
      #   let(:user_name) { 'Adam' }
      #   subject(:user_name) { 'Adam' }
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   let(:user_name) { 'Adam' }
      #   subject(:user_name) { 'Adam' }
      #
      #   # good
      #   let(:userName) { 'Adam' }
      #   subject(:userName) { 'Adam' }
      class VariableName < Cop
        include ConfigurableNaming
        include RuboCop::RSpec::Variable

        MSG = 'Use %<style>s for variable names.'

        def on_send(node)
          variable_definition?(node) do |variable|
            return if variable.dstr_type? || variable.dsym_type?

            check_name(node, variable.value, variable.loc.expression)
          end
        end

        private

        def message(style)
          format(MSG, style: style)
        end
      end
    end
  end
end
