# frozen_string_literal: true

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Script
    #
    # Module Caller provides the convenience method #call_script
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    module Caller
      module_function

      include SidekiqUniqueJobs::Connection

      #
      # Convenience method to reduce typing,
      #   calls redis lua scripts.
      #
      #
      # @param [Symbol] file_name the name of the `script.lua` without extension
      # @param [Array<String>] keys the keys to pass to the script
      # @param [Array<String>] argv any extra arguments to pass
      #
      # @return [true,false,String,Integer,Float,nil] returns the return value of the lua script
      #
      def call_script(file_name, keys = [], argv = [], conn = nil)
        return Script.call(file_name, keys, argv, conn) if conn

        pool = defined?(redis_pool) ? redis_pool : nil

        redis(pool) do |new_conn|
          Script.call(file_name, keys, argv, new_conn)
        end
      end
    end
  end
end
