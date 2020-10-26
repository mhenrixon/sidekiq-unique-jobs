# frozen_string_literal: true

module RuboCop
  module RSpec
    module Corrector
      # Helper methods to move a node
      class MoveNode
        include RuboCop::Cop::RangeHelp
        include RuboCop::RSpec::FinalEndLocation

        attr_reader :original, :corrector, :processed_source

        def initialize(node, corrector, processed_source)
          @original = node
          @corrector = corrector
          @processed_source = processed_source # used by RangeHelp
        end

        def move_before(other)
          position = other.loc.expression
          indent = ' ' * other.loc.column
          newline_indent = "\n#{indent}"

          corrector.insert_before(position, source(original) + newline_indent)
          corrector.remove(node_range_with_surrounding_space(original))
        end

        def move_after(other)
          position = final_end_location(other)
          indent = ' ' * other.loc.column
          newline_indent = "\n#{indent}"

          corrector.insert_after(position, newline_indent + source(original))
          corrector.remove(node_range_with_surrounding_space(original))
        end

        private

        def source(node)
          node_range(node).source
        end

        def node_range(node)
          node.loc.expression.with(end_pos: final_end_location(node).end_pos)
        end

        def node_range_with_surrounding_space(node)
          range = node_range(node)
          range_by_whole_lines(range, include_final_newline: true)
        end
      end
    end
  end
end
