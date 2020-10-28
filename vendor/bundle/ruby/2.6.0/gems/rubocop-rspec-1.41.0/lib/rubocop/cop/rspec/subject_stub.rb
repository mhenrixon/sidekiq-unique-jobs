# frozen_string_literal: true

require 'set'

module RuboCop
  module Cop
    module RSpec
      # Checks for stubbed test subjects.
      #
      # @see https://robots.thoughtbot.com/don-t-stub-the-system-under-test
      # @see https://samphippen.com/introducing-rspec-smells-and-where-to-find-them#smell-1-stubject
      # @see https://github.com/rubocop-hq/rspec-style-guide#dont-stub-subject
      #
      # @example
      #   # bad
      #   describe Foo do
      #     subject(:bar) { baz }
      #
      #     before do
      #       allow(bar).to receive(:qux?).and_return(true)
      #     end
      #   end
      #
      class SubjectStub < Cop
        include RuboCop::RSpec::TopLevelGroup

        MSG = 'Do not stub methods of the object under test.'

        # @!method subject(node)
        #   Find a named or unnamed subject definition
        #
        #   @example anonymous subject
        #     subject(parse('subject { foo }').ast) do |name|
        #       name # => :subject
        #     end
        #
        #   @example named subject
        #     subject(parse('subject(:thing) { foo }').ast) do |name|
        #       name # => :thing
        #     end
        #
        #   @param node [RuboCop::Node]
        #
        #   @yield [Symbol] subject name
        def_node_matcher :subject, <<-PATTERN
          {
            (block (send nil? :subject (sym $_)) args ...)
            (block (send nil? $:subject) args ...)
          }
        PATTERN

        # @!method message_expectation?(node, method_name)
        #   Match `allow` and `expect(...).to receive`
        #
        #   @example source that matches
        #     allow(foo).to  receive(:bar)
        #     allow(foo).to  receive(:bar).with(1)
        #     allow(foo).to  receive(:bar).with(1).and_return(2)
        #     expect(foo).to receive(:bar)
        #     expect(foo).to receive(:bar).with(1)
        #     expect(foo).to receive(:bar).with(1).and_return(2)
        #
        def_node_matcher :message_expectation?, <<-PATTERN
          (send
            {
              (send nil? { :expect :allow } (send nil? {% :subject}))
              (send nil? :is_expected)
            }
            #{Runners::ALL.node_pattern_union}
            #message_expectation_matcher?
          )
        PATTERN

        def_node_search :message_expectation_matcher?, <<-PATTERN
          (send nil? {
            :receive :receive_messages :receive_message_chain :have_received
            } ...)
        PATTERN

        def on_top_level_group(node)
          @explicit_subjects = find_all_explicit_subjects(node)

          find_subject_expectations(node) do |stub|
            add_offense(stub)
          end
        end

        private

        def find_all_explicit_subjects(node)
          node.each_descendant(:block).with_object({}) do |child, h|
            name = subject(child)
            next unless name

            outer_example_group = child.each_ancestor.find do |a|
              example_group?(a)
            end

            h[outer_example_group] ||= []
            h[outer_example_group] << name
          end
        end

        def find_subject_expectations(node, subject_names = [], &block)
          subject_names = @explicit_subjects[node] if @explicit_subjects[node]

          expectation_detected = (subject_names + [:subject]).any? do |name|
            message_expectation?(node, name)
          end
          return yield(node) if expectation_detected

          node.each_child_node do |child|
            find_subject_expectations(child, subject_names, &block)
          end
        end
      end
    end
  end
end
