# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks invalid usage for predicate matcher.
      #
      # Predicate matcher does not need a question.
      # This cop checks an unnecessary question in predicate matcher.
      #
      # @example
      #
      #   # bad
      #   expect(foo).to be_something?
      #
      #   # good
      #   expect(foo).to be_something
      class InvalidPredicateMatcher < Cop
        MSG = 'Omit `?` from `%<matcher>s`.'

        def_node_matcher :invalid_predicate_matcher?, <<-PATTERN
          (send (send nil? :expect ...) #{Runners::ALL.node_pattern_union} $(send nil? #predicate?))
        PATTERN

        def on_send(node)
          invalid_predicate_matcher?(node) do |predicate|
            add_offense(predicate)
          end
        end

        private

        def predicate?(name)
          name = name.to_s
          name.start_with?('be_', 'have_') && name.end_with?('?')
        end

        def message(predicate)
          format(MSG, matcher: predicate.method_name)
        end
      end
    end
  end
end
