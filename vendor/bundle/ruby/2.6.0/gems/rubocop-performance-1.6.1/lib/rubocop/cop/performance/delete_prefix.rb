# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.5, `String#delete_prefix` has been added.
      #
      # This cop identifies places where `gsub(/\Aprefix/, '')` and `sub(/\Aprefix/, '')`
      # can be replaced by `delete_prefix('prefix')`.
      #
      # This cop has `SafeMultiline` configuration option that `true` by default because
      # `^prefix` is unsafe as it will behave incompatible with `delete_prefix`
      # for receiver is multiline string.
      #
      # The `delete_prefix('prefix')` method is faster than `gsub(/\Aprefix/, '')`.
      #
      # @example
      #
      #   # bad
      #   str.gsub(/\Aprefix/, '')
      #   str.gsub!(/\Aprefix/, '')
      #
      #   str.sub(/\Aprefix/, '')
      #   str.sub!(/\Aprefix/, '')
      #
      #   # good
      #   str.delete_prefix('prefix')
      #   str.delete_prefix!('prefix')
      #
      # @example SafeMultiline: true (default)
      #
      #   # good
      #   str.gsub(/^prefix/, '')
      #   str.gsub!(/^prefix/, '')
      #   str.sub(/^prefix/, '')
      #   str.sub!(/^prefix/, '')
      #
      # @example SafeMultiline: false
      #
      #   # bad
      #   str.gsub(/^prefix/, '')
      #   str.gsub!(/^prefix/, '')
      #   str.sub(/^prefix/, '')
      #   str.sub!(/^prefix/, '')
      #
      class DeletePrefix < Cop
        extend TargetRubyVersion
        include RegexpMetacharacter

        minimum_target_ruby_version 2.5

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'

        PREFERRED_METHODS = {
          gsub: :delete_prefix,
          gsub!: :delete_prefix!,
          sub: :delete_prefix,
          sub!: :delete_prefix!
        }.freeze

        def_node_matcher :delete_prefix_candidate?, <<~PATTERN
          (send $!nil? ${:gsub :gsub! :sub :sub!} (regexp (str $#literal_at_start?) (regopt)) (str $_))
        PATTERN

        def on_send(node)
          delete_prefix_candidate?(node) do |_, bad_method, _, replace_string|
            return unless replace_string.blank?

            good_method = PREFERRED_METHODS[bad_method]

            message = format(MSG, current: bad_method, prefer: good_method)

            add_offense(node, location: :selector, message: message)
          end
        end

        def autocorrect(node)
          delete_prefix_candidate?(node) do |receiver, bad_method, regexp_str, _|
            lambda do |corrector|
              good_method = PREFERRED_METHODS[bad_method]
              regexp_str = drop_start_metacharacter(regexp_str)
              regexp_str = interpret_string_escapes(regexp_str)
              string_literal = to_string_literal(regexp_str)

              new_code = "#{receiver.source}.#{good_method}(#{string_literal})"

              # TODO: `source_range` is no longer required when RuboCop 0.81 or lower support will be dropped.
              # https://github.com/rubocop-hq/rubocop/commit/82eb350d2cba16
              corrector.replace(node.source_range, new_code)
            end
          end
        end
      end
    end
  end
end
