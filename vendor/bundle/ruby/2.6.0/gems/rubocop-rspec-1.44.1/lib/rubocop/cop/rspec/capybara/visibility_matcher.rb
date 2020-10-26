# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Capybara
        # Checks for boolean visibility in capybara finders.
        #
        # Capybara lets you find elements that match a certain visibility using
        # the `:visible` option. `:visible` accepts both boolean and symbols as
        # values, however using booleans can have unwanted effects. `visible:
        # false` does not find just invisible elements, but both visible and
        # invisible elements. For expressiveness and clarity, use one of the
        # symbol values, `:all`, `:hidden` or `:visible`.
        # (https://www.rubydoc.info/gems/capybara/Capybara%2FNode%2FFinders:all)
        #
        # @example
        #
        #   # bad
        #   expect(page).to have_selector('.foo', visible: false)
        #   expect(page).to have_css('.foo', visible: true)
        #   expect(page).to have_link('my link', visible: false)
        #
        #   # good
        #   expect(page).to have_selector('.foo', visible: :visible)
        #   expect(page).to have_css('.foo', visible: :all)
        #   expect(page).to have_link('my link', visible: :hidden)
        #
        class VisibilityMatcher < Base
          MSG_FALSE = 'Use `:all` or `:hidden` instead of `false`.'
          MSG_TRUE = 'Use `:visible` instead of `true`.'
          CAPYBARA_MATCHER_METHODS = %i[
            have_selector
            have_css
            have_xpath
            have_link
            have_button
            have_field
            have_select
            have_table
            have_checked_field
            have_unchecked_field
            have_text
            have_content
          ].freeze

          def_node_matcher :visible_true?, <<~PATTERN
            (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) true) ...>))
          PATTERN

          def_node_matcher :visible_false?, <<~PATTERN
            (send nil? #capybara_matcher? ... (hash <$(pair (sym :visible) false) ...>))
          PATTERN

          def on_send(node)
            visible_false?(node) { |arg| add_offense(arg, message: MSG_FALSE) }
            visible_true?(node) { |arg| add_offense(arg, message: MSG_TRUE) }
          end

          private

          def capybara_matcher?(method_name)
            CAPYBARA_MATCHER_METHODS.include? method_name
          end
        end
      end
    end
  end
end
