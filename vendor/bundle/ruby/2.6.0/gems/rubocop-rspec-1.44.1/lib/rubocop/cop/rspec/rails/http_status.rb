# frozen_string_literal: true

require 'rack/utils'

module RuboCop
  module Cop
    module RSpec
      module Rails
        # Enforces use of symbolic or numeric value to describe HTTP status.
        #
        # @example `EnforcedStyle: symbolic` (default)
        #   # bad
        #   it { is_expected.to have_http_status 200 }
        #   it { is_expected.to have_http_status 404 }
        #
        #   # good
        #   it { is_expected.to have_http_status :ok }
        #   it { is_expected.to have_http_status :not_found }
        #   it { is_expected.to have_http_status :success }
        #   it { is_expected.to have_http_status :error }
        #
        # @example `EnforcedStyle: numeric`
        #   # bad
        #   it { is_expected.to have_http_status :ok }
        #   it { is_expected.to have_http_status :not_found }
        #
        #   # good
        #   it { is_expected.to have_http_status 200 }
        #   it { is_expected.to have_http_status 404 }
        #   it { is_expected.to have_http_status :success }
        #   it { is_expected.to have_http_status :error }
        #
        class HttpStatus < Base
          extend AutoCorrector
          include ConfigurableEnforcedStyle

          def_node_matcher :http_status, <<-PATTERN
            (send nil? :have_http_status ${int sym})
          PATTERN

          def on_send(node)
            http_status(node) do |ast_node|
              checker = checker_class.new(ast_node)
              return unless checker.offensive?

              add_offense(checker.node, message: checker.message) do |corrector|
                corrector.replace(checker.node, checker.preferred_style)
              end
            end
          end

          private

          def checker_class
            case style
            when :symbolic
              SymbolicStyleChecker
            when :numeric
              NumericStyleChecker
            end
          end

          # :nodoc:
          class SymbolicStyleChecker
            MSG = 'Prefer `%<prefer>s` over `%<current>s` ' \
                  'to describe HTTP status code.'

            attr_reader :node

            def initialize(node)
              @node = node
            end

            def offensive?
              !node.sym_type? && !custom_http_status_code?
            end

            def message
              format(MSG, prefer: preferred_style, current: number.to_s)
            end

            def preferred_style
              symbol.inspect
            end

            private

            def symbol
              ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key(number)
            end

            def number
              node.source.to_i
            end

            def custom_http_status_code?
              node.int_type? &&
                !::Rack::Utils::SYMBOL_TO_STATUS_CODE.value?(node.source.to_i)
            end
          end

          # :nodoc:
          class NumericStyleChecker
            MSG = 'Prefer `%<prefer>s` over `%<current>s` ' \
                  'to describe HTTP status code.'

            ALLOWED_STATUSES = %i[error success missing redirect].freeze

            attr_reader :node

            def initialize(node)
              @node = node
            end

            def offensive?
              !node.int_type? && !allowed_symbol?
            end

            def message
              format(MSG, prefer: preferred_style, current: symbol.inspect)
            end

            def preferred_style
              number.to_s
            end

            private

            def number
              ::Rack::Utils::SYMBOL_TO_STATUS_CODE[symbol]
            end

            def symbol
              node.value
            end

            def allowed_symbol?
              node.sym_type? && ALLOWED_STATUSES.include?(node.value)
            end
          end
        end
      end
    end
  end
end
