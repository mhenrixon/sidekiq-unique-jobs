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
      # @param [Hash] options arguments to pass to the script file
      # @option options [Array] :keys the array of keys to pass to the script
      # @option options [Array] :argv the array of arguments to pass to the script
      #
      # @return [true,false,String,Integer,Float,nil] returns the return value of the lua script
      #
      #
      # <description>
      #
      # @param [<type>] file_name <description>
      # @param [<type>] *args <description>
      #
      # @return [<type>] <description>
      #
      def call_script(file_name, *args)
        conn, keys, argv = extract_args(*args)
        return Script.call(file_name, conn, keys: keys, argv: argv) if conn

        pool = defined?(redis_pool) ? redis_pool : nil

        redis(pool) do |new_conn|
          Script.call(file_name, new_conn, keys: keys, argv: argv)
        end
      end

      #
      # Utility method to allow both symbol keys and arguments
      #
      # @param [<type>] *args <description>
      #
      # @return [<type>] <description>
      #
      def extract_args(*args)
        options = args.extract_options!
        if options.length.positive?
          [args.pop, options.fetch(:keys) { [] }, options.fetch(:argv) { [] }]
        else
          keys, argv = args.shift(2)
          keys ||= []
          argv ||= []
          [args.pop, keys, argv]
        end
      end
    end
  end
end
