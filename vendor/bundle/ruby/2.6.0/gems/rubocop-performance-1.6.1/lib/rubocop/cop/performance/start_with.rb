# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop identifies unnecessary use of a regex where `String#start_with?` would suffice.
      #
      # This cop has `SafeMultiline` configuration option that `true` by default because
      # `^start` is unsafe as it will behave incompatible with `start_with?`
      # for receiver is multiline string.
      #
      # @example
      #   # bad
      #   'abc'.match?(/\Aab/)
      #   /\Aab/.match?('abc')
      #   'abc' =~ /\Aab/
      #   /\Aab/ =~ 'abc'
      #   'abc'.match(/\Aab/)
      #   /\Aab/.match('abc')
      #
      #   # good
      #   'abc'.start_with?('ab')
      #
      # @example SafeMultiline: true (default)
      #
      #   # good
      #   'abc'.match?(/^ab/)
      #   /^ab/.match?('abc')
      #   'abc' =~ /^ab/
      #   /^ab/ =~ 'abc'
      #   'abc'.match(/^ab/)
      #   /^ab/.match('abc')
      #
      # @example SafeMultiline: false
      #
      #   # bad
      #   'abc'.match?(/^ab/)
      #   /^ab/.match?('abc')
      #   'abc' =~ /^ab/
      #   /^ab/ =~ 'abc'
      #   'abc'.match(/^ab/)
      #   /^ab/.match('abc')
      #
      class StartWith < Cop
        include RegexpMetacharacter

        MSG = 'Use `String#start_with?` instead of a regex match anchored to ' \
              'the beginning of the string.'

        def_node_matcher :redundant_regex?, <<~PATTERN
          {(send $!nil? {:match :=~ :match?} (regexp (str $#literal_at_start?) (regopt)))
           (send (regexp (str $#literal_at_start?) (regopt)) {:match :match?} $_)
           (match-with-lvasgn (regexp (str $#literal_at_start?) (regopt)) $_)}
        PATTERN

        def on_send(node)
          return unless redundant_regex?(node)

          add_offense(node)
        end
        alias on_match_with_lvasgn on_send

        def autocorrect(node)
          redundant_regex?(node) do |receiver, regex_str|
            receiver, regex_str = regex_str, receiver if receiver.is_a?(String)
            regex_str = drop_start_metacharacter(regex_str)
            regex_str = interpret_string_escapes(regex_str)

            lambda do |corrector|
              new_source = receiver.source + '.start_with?(' +
                           to_string_literal(regex_str) + ')'
              corrector.replace(node.source_range, new_source)
            end
          end
        end
      end
    end
  end
end
