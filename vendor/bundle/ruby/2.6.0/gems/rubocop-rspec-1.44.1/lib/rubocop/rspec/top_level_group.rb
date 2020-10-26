# frozen_string_literal: true

module RuboCop
  module RSpec
    # Helper methods for top level example group cops
    module TopLevelGroup
      extend RuboCop::NodePattern::Macros
      include RuboCop::RSpec::Language

      def_node_matcher :example_or_shared_group?,
                       (ExampleGroups::ALL + SharedGroups::ALL).block_pattern

      def on_new_investigation
        super

        return unless root_node

        top_level_groups.each do |node|
          on_top_level_example_group(node) if example_group?(node)
          on_top_level_group(node)
        end
      end

      def top_level_groups
        @top_level_groups ||=
          top_level_nodes(root_node).select { |n| example_or_shared_group?(n) }
      end

      private

      # Dummy methods to be overridden in the consumer
      def on_top_level_example_group(_node); end

      def on_top_level_group(_node); end

      def top_level_group?(node)
        top_level_groups.include?(node)
      end

      def top_level_nodes(node)
        if node.nil?
          []
        elsif node.begin_type?
          node.children
        elsif node.module_type? || node.class_type?
          top_level_nodes(node.body)
        else
          [node]
        end
      end

      def root_node
        processed_source.ast
      end
    end
  end
end
