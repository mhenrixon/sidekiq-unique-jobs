# frozen_string_literal: true

module RuboCop
  module Cop
    module ThreadSafety
      # This cop checks whether some class instance variable isn't a
      # mutable literal (e.g. array or hash).
      #
      # It is based on Style/MutableConstant from RuboCop.
      # See https://github.com/rubocop-hq/rubocop/blob/master/lib/rubocop/cop/style/mutable_constant.rb
      #
      # Class instance variables are a risk to threaded code as they are shared
      # between threads. A mutable object such as an array or hash may be
      # updated via an attr_reader so would not be detected by the
      # ThreadSafety/ClassAndModuleAttributes cop.
      #
      # Strict mode can be used to freeze all class instance variables, rather
      # than just literals.
      # Strict mode is considered an experimental feature. It has not been
      # updated with an exhaustive list of all methods that will produce frozen
      # objects so there is a decent chance of getting some false positives.
      # Luckily, there is no harm in freezing an already frozen object.
      #
      # @example EnforcedStyle: literals (default)
      #   # bad
      #   class Model
      #     @list = [1, 2, 3]
      #   end
      #
      #   # good
      #   class Model
      #     @list = [1, 2, 3].freeze
      #   end
      #
      #   # good
      #   class Model
      #     @var = <<-TESTING.freeze
      #       This is a heredoc
      #     TESTING
      #   end
      #
      #   # good
      #   class Model
      #     @var = Something.new
      #   end
      #
      # @example EnforcedStyle: strict
      #   # bad
      #   class Model
      #     @var = Something.new
      #   end
      #
      #   # bad
      #   class Model
      #     @var = Struct.new do
      #       def foo
      #         puts 1
      #       end
      #     end
      #   end
      #
      #   # good
      #   class Model
      #     @var = Something.new.freeze
      #   end
      #
      #   # good
      #   class Model
      #     @var = Struct.new do
      #       def foo
      #         puts 1
      #       end
      #     end.freeze
      #   end
      class MutableClassInstanceVariable < Cop
        include FrozenStringLiteral
        include ConfigurableEnforcedStyle

        MSG = 'Freeze mutable objects assigned to class instance variables.'

        def on_ivasgn(node)
          return unless in_class?(node)

          _, value = *node
          on_assignment(value)
        end

        def on_or_asgn(node)
          lhs, value = *node
          return unless lhs&.ivasgn_type?
          return unless in_class?(node)

          on_assignment(value)
        end

        def on_masgn(node)
          return unless in_class?(node)

          mlhs, values = *node
          return unless values.array_type?

          mlhs.to_a.zip(values.to_a).each do |lhs, value|
            next unless lhs.ivasgn_type?

            on_assignment(value)
          end
        end

        def autocorrect(node)
          expr = node.source_range

          lambda do |corrector|
            splat_value = splat_value(node)
            if splat_value
              correct_splat_expansion(corrector, expr, splat_value)
            elsif node.array_type? && !node.bracketed?
              corrector.insert_before(expr, '[')
              corrector.insert_after(expr, ']')
            elsif requires_parentheses?(node)
              corrector.insert_before(expr, '(')
              corrector.insert_after(expr, ')')
            end

            corrector.insert_after(expr, '.freeze')
          end
        end

        private

        def on_assignment(value)
          if style == :strict
            strict_check(value)
          else
            check(value)
          end
        end

        def strict_check(value)
          return if immutable_literal?(value)
          return if operation_produces_immutable_object?(value)
          return if frozen_string_literal?(value)

          add_offense(value)
        end

        def check(value)
          return unless mutable_literal?(value) ||
                        range_enclosed_in_parentheses?(value)
          return if frozen_string_literal?(value)

          add_offense(value)
        end

        def in_class?(node)
          container = node.ancestors.find do |ancestor|
            container?(ancestor)
          end
          return false if container.nil?

          %i[class module].include?(container.type)
        end

        def container?(node)
          return true if define_singleton_method?(node)

          %i[def defs class module].include?(node.type)
        end

        def mutable_literal?(node)
          node&.mutable_literal?
        end

        def immutable_literal?(node)
          node.nil? || node.immutable_literal?
        end

        def frozen_string_literal?(node)
          FROZEN_STRING_LITERAL_TYPES.include?(node.type) &&
            frozen_string_literals_enabled?
        end

        def requires_parentheses?(node)
          node.range_type? ||
            (node.send_type? && node.loc.dot.nil?)
        end

        def correct_splat_expansion(corrector, expr, splat_value)
          if range_enclosed_in_parentheses?(splat_value)
            corrector.replace(expr, "#{splat_value.source}.to_a")
          else
            corrector.replace(expr, "(#{splat_value.source}).to_a")
          end
        end

        def_node_matcher :define_singleton_method?, <<-PATTERN
          (block (send nil? :define_singleton_method ...) ...)
        PATTERN

        def_node_matcher :splat_value, <<-PATTERN
          (array (splat $_))
        PATTERN

        # NOTE: Some of these patterns may not actually return an immutable
        # object but we will consider them immutable for this cop.
        def_node_matcher :operation_produces_immutable_object?, <<-PATTERN
          {
            (const _ _)
            (send (const nil? :Struct) :new ...)
            (block (send (const nil? :Struct) :new ...) ...)
            (send _ :freeze)
            (send {float int} {:+ :- :* :** :/ :% :<<} _)
            (send _ {:+ :- :* :** :/ :%} {float int})
            (send _ {:== :=== :!= :<= :>= :< :>} _)
            (send (const nil? :ENV) :[] _)
            (or (send (const nil? :ENV) :[] _) _)
            (send _ {:count :length :size} ...)
            (block (send _ {:count :length :size} ...) ...)
          }
        PATTERN

        def_node_matcher :range_enclosed_in_parentheses?, <<-PATTERN
          (begin ({irange erange} _ _))
        PATTERN
      end
    end
  end
end
