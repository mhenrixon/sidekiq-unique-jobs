# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks unreferenced `let!` calls being used for test setup.
      #
      # @example
      #   # Bad
      #   let!(:my_widget) { create(:widget) }
      #
      #   it 'counts widgets' do
      #     expect(Widget.count).to eq(1)
      #   end
      #
      #   # Good
      #   it 'counts widgets' do
      #     create(:widget)
      #     expect(Widget.count).to eq(1)
      #   end
      #
      #   # Good
      #   before { create(:widget) }
      #
      #   it 'counts widgets' do
      #     expect(Widget.count).to eq(1)
      #   end
      class LetSetup < Cop
        MSG = 'Do not use `let!` to setup objects not referenced in tests.'

        def_node_matcher :example_or_shared_group_or_including?,
                         (
                           ExampleGroups::ALL + SharedGroups::ALL +
                           Includes::ALL
                         ).block_pattern

        def_node_matcher :let_bang, <<-PATTERN
          (block $(send nil? :let! (sym $_)) args ...)
        PATTERN

        def_node_search :method_called?, '(send nil? %)'

        def on_block(node)
          return unless example_or_shared_group_or_including?(node)

          unused_let_bang(node) do |let|
            add_offense(let)
          end
        end

        private

        def unused_let_bang(node)
          child_let_bang(node) do |method_send, method_name|
            yield(method_send) unless method_called?(node, method_name)
          end
        end

        def child_let_bang(node, &block)
          RuboCop::RSpec::ExampleGroup.new(node).lets.each do |let|
            let_bang(let, &block)
          end
        end
      end
    end
  end
end
