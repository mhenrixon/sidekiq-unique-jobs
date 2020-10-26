# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks the arguments passed to `before`, `around`, and `after`.
      #
      # This cop checks for consistent style when specifying RSpec
      # hooks which run for each example. There are three supported
      # styles: "implicit", "each", and "example." All styles have
      # the same behavior.
      #
      # @example when configuration is `EnforcedStyle: implicit`
      #   # bad
      #   before(:each) do
      #     # ...
      #   end
      #
      #   # bad
      #   before(:example) do
      #     # ...
      #   end
      #
      #   # good
      #   before do
      #     # ...
      #   end
      #
      # @example when configuration is `EnforcedStyle: each`
      #   # bad
      #   before(:example) do
      #     # ...
      #   end
      #
      #   # good
      #   before do
      #     # ...
      #   end
      #
      #   # good
      #   before(:each) do
      #     # ...
      #   end
      #
      # @example when configuration is `EnforcedStyle: example`
      #   # bad
      #   before(:each) do
      #     # ...
      #   end
      #
      #   # bad
      #   before do
      #     # ...
      #   end
      #
      #   # good
      #   before(:example) do
      #     # ...
      #   end
      class HookArgument < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        IMPLICIT_MSG = 'Omit the default `%<scope>p` argument for RSpec hooks.'
        EXPLICIT_MSG = 'Use `%<scope>p` for RSpec hooks.'

        def_node_matcher :hook?, Hooks::ALL.node_pattern_union

        def_node_matcher :scoped_hook, <<-PATTERN
          (block $(send _ #hook? (sym ${:each :example})) ...)
        PATTERN

        def_node_matcher :unscoped_hook, '(block $(send _ #hook?) ...)'

        def on_block(node)
          hook(node) do |method_send, scope_name|
            return correct_style_detected if scope_name.equal?(style)
            return check_implicit(method_send) unless scope_name

            style_detected(scope_name)
            msg = explicit_message(scope_name)
            add_offense(method_send, message: msg) do |corrector|
              scope = implicit_style? ? '' : "(#{style.inspect})"
              corrector.replace(argument_range(method_send), scope)
            end
          end
        end

        private

        def check_implicit(method_send)
          style_detected(:implicit)
          return if implicit_style?

          msg = explicit_message(nil)
          add_offense(method_send.loc.selector, message: msg) do |corrector|
            scope = "(#{style.inspect})"
            corrector.replace(argument_range(method_send), scope)
          end
        end

        def explicit_message(scope)
          if implicit_style?
            format(IMPLICIT_MSG, scope: scope)
          else
            format(EXPLICIT_MSG, scope: style)
          end
        end

        def implicit_style?
          style.equal?(:implicit)
        end

        def hook(node, &block)
          scoped_hook(node, &block) || unscoped_hook(node, &block)
        end

        def argument_range(send_node)
          send_node.loc.selector.end.with(
            end_pos: send_node.loc.expression.end_pos
          )
        end
      end
    end
  end
end
