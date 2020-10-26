# frozen_string_literal: true

module RuboCop
  module Cop
    module ThreadSafety
      # Avoid starting new threads.
      #
      # Let a framework like Sidekiq handle the threads.
      #
      # @example
      #   # bad
      #   Thread.new { do_work }
      class NewThread < Cop
        MSG = 'Avoid starting new threads.'

        def_node_matcher :new_thread?, <<-MATCHER
          (send (const nil? :Thread) :new)
        MATCHER

        def on_send(node)
          return unless new_thread?(node)

          add_offense(node, message: MSG)
        end
      end
    end
  end
end
