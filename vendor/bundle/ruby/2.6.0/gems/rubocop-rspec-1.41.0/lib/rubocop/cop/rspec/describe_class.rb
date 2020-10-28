# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that the first argument to the top level describe is a constant.
      #
      # @example
      #   # bad
      #   describe 'Do something' do
      #   end
      #
      #   # good
      #   describe TestedClass do
      #     subject { described_class }
      #   end
      #
      #   describe 'TestedClass::VERSION' do
      #     subject { Object.const_get(self.class.description) }
      #   end
      #
      #   describe "A feature example", type: :feature do
      #   end
      class DescribeClass < Cop
        include RuboCop::RSpec::TopLevelDescribe

        MSG = 'The first argument to describe should be '\
              'the class or module being tested.'

        def_node_matcher :valid_describe?, <<-PATTERN
          {
            (send #{RSPEC} :describe const ...)
            (send #{RSPEC} :describe)
          }
        PATTERN

        def_node_matcher :describe_with_rails_metadata?, <<-PATTERN
          (send #{RSPEC} :describe !const ...
            (hash <#rails_metadata? ...>)
          )
        PATTERN

        def_node_matcher :rails_metadata?, <<-PATTERN
          (pair
            (sym :type)
            (sym {
                   :channel :controller :helper :job :mailer :model :request
                   :routing :view :feature :system :mailbox
                 }
            )
          )
        PATTERN

        def on_top_level_describe(node, (described_value, _))
          return if shared_group?(root_node)
          return if valid_describe?(node)
          return if describe_with_rails_metadata?(node)
          return if string_constant_describe?(described_value)

          add_offense(described_value)
        end

        private

        def string_constant_describe?(described_value)
          described_value.str_type? &&
            described_value.value =~ /^((::)?[A-Z]\w*)+$/
        end
      end
    end
  end
end
