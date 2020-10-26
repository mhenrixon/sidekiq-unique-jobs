# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # This cop identifies places where custom code finding the sum of elements
      # in some Enumerable object can be replaced by `Enumerable#sum` method.
      #
      # @example
      #   # bad
      #   [1, 2, 3].inject(:+)
      #   [1, 2, 3].reduce(10, :+)
      #   [1, 2, 3].inject(&:+)
      #   [1, 2, 3].reduce { |acc, elem| acc + elem }
      #
      #   # good
      #   [1, 2, 3].sum
      #   [1, 2, 3].sum(10)
      #   [1, 2, 3].sum
      #
      class Sum < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<good_method>s` instead of `%<bad_method>s`.'

        def_node_matcher :sum_candidate?, <<~PATTERN
          (send _ ${:inject :reduce} $_init ? ${(sym :+) (block_pass (sym :+))})
        PATTERN

        def_node_matcher :sum_with_block_candidate?, <<~PATTERN
          (block
            $(send _ {:inject :reduce} $_init ?)
            (args (arg $_acc) (arg $_elem))
            $send)
        PATTERN

        def_node_matcher :acc_plus_elem?, <<~PATTERN
          (send (lvar %1) :+ (lvar %2))
        PATTERN
        alias elem_plus_acc? acc_plus_elem?

        def on_send(node)
          sum_candidate?(node) do |method, init, operation|
            range = sum_method_range(node)
            message = build_method_message(method, init, operation)

            add_offense(range, message: message) do |corrector|
              autocorrect(corrector, init, range)
            end
          end
        end

        def on_block(node)
          sum_with_block_candidate?(node) do |send, init, var_acc, var_elem, body|
            if acc_plus_elem?(body, var_acc, var_elem) || elem_plus_acc?(body, var_elem, var_acc)
              range = sum_block_range(send, node)
              message = build_block_message(send, init, var_acc, var_elem, body)

              add_offense(range, message: message) do |corrector|
                autocorrect(corrector, init, range)
              end
            end
          end
        end

        private

        def autocorrect(corrector, init, range)
          return if init.empty?

          replacement = build_good_method(init)

          corrector.replace(range, replacement)
        end

        def sum_method_range(node)
          range_between(node.loc.selector.begin_pos, node.loc.end.end_pos)
        end

        def sum_block_range(send, node)
          range_between(send.loc.selector.begin_pos, node.loc.end.end_pos)
        end

        def build_method_message(method, init, operation)
          good_method = build_good_method(init)
          bad_method = build_method_bad_method(init, method, operation)
          format(MSG, good_method: good_method, bad_method: bad_method)
        end

        def build_block_message(send, init, var_acc, var_elem, body)
          good_method = build_good_method(init)
          bad_method = build_block_bad_method(send.method_name, init, var_acc, var_elem, body)
          format(MSG, good_method: good_method, bad_method: bad_method)
        end

        def build_good_method(init)
          good_method = 'sum'

          unless init.empty?
            init = init.first
            good_method += "(#{init.source})" unless init.int_type? && init.value.zero?
          end
          good_method
        end

        def build_method_bad_method(init, method, operation)
          bad_method = "#{method}("
          unless init.empty?
            init = init.first
            bad_method += "#{init.source}, "
          end
          bad_method += if operation.block_pass_type?
                          '&:+)'
                        else
                          ':+)'
                        end
          bad_method
        end

        def build_block_bad_method(method, init, var_acc, var_elem, body)
          bad_method = method.to_s

          unless init.empty?
            init = init.first
            bad_method += "(#{init.source})"
          end
          bad_method += " { |#{var_acc}, #{var_elem}| #{body.source} }"
          bad_method
        end
      end
    end
  end
end
