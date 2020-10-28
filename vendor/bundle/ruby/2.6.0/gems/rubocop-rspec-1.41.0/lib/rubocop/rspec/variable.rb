# frozen_string_literal: true

module RuboCop
  module RSpec
    # Helps check offenses with variable definitions
    module Variable
      include Language
      extend RuboCop::NodePattern::Macros

      def_node_matcher :variable_definition?, <<~PATTERN
        (send #{RSPEC} #{(Helpers::ALL + Subject::ALL).node_pattern_union}
          $({sym str dsym dstr} ...) ...)
      PATTERN
    end
  end
end
