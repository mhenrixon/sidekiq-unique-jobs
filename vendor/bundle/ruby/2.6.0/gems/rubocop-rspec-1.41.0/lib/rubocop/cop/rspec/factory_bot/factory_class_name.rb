# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # Use string value when setting the class attribute explicitly.
        #
        # This cop would promote faster tests by lazy-loading of
        # application files. Also, this could help you suppress potential bugs
        # in combination with external libraries by avoiding a preload of
        # application files from the factory files.
        #
        # @example
        #   # bad
        #   factory :foo, class: Foo do
        #   end
        #
        #   # good
        #   factory :foo, class: 'Foo' do
        #   end
        class FactoryClassName < Cop
          MSG = "Pass '%<class_name>s' string instead of `%<class_name>s` " \
                'constant.'
          ALLOWED_CONSTANTS = %w[Hash OpenStruct].freeze

          def_node_matcher :class_name, <<~PATTERN
            (send _ :factory _ (hash <(pair (sym :class) $(const ...)) ...>))
          PATTERN

          def on_send(node)
            class_name(node) do |cn|
              next if allowed?(cn.const_name)

              add_offense(cn, message: format(MSG, class_name: cn.const_name))
            end
          end

          def autocorrect(node)
            lambda do |corrector|
              corrector.replace(node.loc.expression, "'#{node.source}'")
            end
          end

          private

          def allowed?(const_name)
            ALLOWED_CONSTANTS.include?(const_name)
          end
        end
      end
    end
  end
end
