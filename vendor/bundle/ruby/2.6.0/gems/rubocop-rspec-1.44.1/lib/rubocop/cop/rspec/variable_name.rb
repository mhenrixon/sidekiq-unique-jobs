# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that memoized helper names use the configured style.
      #
      # Variables can be excluded from checking using the `IgnoredPatterns`
      # option.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   subject(:userName1) { 'Adam' }
      #   let(:userName2) { 'Adam' }
      #
      #   # good
      #   subject(:user_name_1) { 'Adam' }
      #   let(:user_name_2) { 'Adam' }
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   subject(:user_name_1) { 'Adam' }
      #   let(:user_name_2) { 'Adam' }
      #
      #   # good
      #   subject(:userName1) { 'Adam' }
      #   let(:userName2) { 'Adam' }
      #
      # @example IgnoredPatterns configuration
      #
      #   # rubocop.yml
      #   # RSpec/VariableName:
      #   #   EnforcedStyle: snake_case
      #   #   IgnoredPatterns:
      #   #     - ^userFood
      #
      # @example
      #   # okay because it matches the `^userFood` regex in `IgnoredPatterns`
      #   subject(:userFood_1) { 'spaghetti' }
      #   let(:userFood_2) { 'fettuccine' }
      #
      class VariableName < Base
        include ConfigurableNaming
        include IgnoredPattern
        include RuboCop::RSpec::Variable

        MSG = 'Use %<style>s for variable names.'

        def on_send(node)
          variable_definition?(node) do |variable|
            return if variable.dstr_type? || variable.dsym_type?
            return if matches_ignored_pattern?(variable.value)

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
