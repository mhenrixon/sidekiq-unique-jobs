# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that memoized helpers names are symbols or strings.
      #
      # @example EnforcedStyle: symbols (default)
      #   # bad
      #   let('user_name') { 'Adam' }
      #   subject('user') { create_user }
      #
      #   # good
      #   let(:user_name) { 'Adam' }
      #   subject(:user) { create_user }
      #
      # @example EnforcedStyle: strings
      #   # bad
      #   let(:user_name) { 'Adam' }
      #   subject(:user) { create_user }
      #
      #   # good
      #   let('user_name') { 'Adam' }
      #   subject('user') { create_user }
      class VariableDefinition < Cop
        include ConfigurableEnforcedStyle
        include RuboCop::RSpec::Variable

        MSG = 'Use %<style>s for variable names.'

        def on_send(node)
          variable_definition?(node) do |variable|
            if style_violation?(variable)
              add_offense(variable, message: format(MSG, style: style))
            end
          end
        end

        private

        def style_violation?(variable)
          style == :symbols && string?(variable) ||
            style == :strings && symbol?(variable)
        end

        def string?(node)
          node.str_type? || node.dstr_type?
        end

        def symbol?(node)
          node.sym_type? || node.dsym_type?
        end
      end
    end
  end
end
