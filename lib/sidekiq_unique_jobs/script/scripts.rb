# frozen_string_literal: true

module SidekiqUniqueJobs
  module Script
    # Interface to dealing with .lua files
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Scripts
      #
      # @return [Concurrent::Map] a map with configured script paths
      SCRIPT_PATHS = Concurrent::Map.new

      #
      # Fetch or create a scripts configuration for path
      #
      # Uses Concurrent::Map#fetch_or_store for thread-safe lazy initialization
      #
      # @param [Pathname] root_path the path to scripts
      #
      # @return [Scripts] a collection of scripts
      #
      def self.fetch(root_path)
        SCRIPT_PATHS.fetch_or_store(root_path) { new(root_path) }
      end

      #
      # @!attribute [r] scripts
      #   @return [Concurrent::Map] a collection of loaded scripts
      attr_reader :scripts

      #
      # @!attribute [r] root_path
      #   @return [Pathname] the path to the directory with lua scripts
      attr_reader :root_path

      def initialize(path)
        raise ArgumentError, "path needs to be a Pathname" unless path.is_a?(Pathname)

        @scripts   = Concurrent::Map.new
        @root_path = path
      end

      #
      # Fetch or load a script by name
      #
      # Uses Concurrent::Map#fetch_or_store for thread-safe lazy loading
      #
      # @param [Symbol, String] name the script name
      # @param [Redis] conn the redis connection
      #
      # @return [Script] the loaded script
      #
      def fetch(name, conn)
        scripts.fetch_or_store(name.to_sym) { load(name, conn) }
      end

      #
      # Load a script from disk, store in Redis, and cache in memory
      #
      # @param [Symbol, String] name the script name
      # @param [Redis] conn the redis connection
      #
      # @return [Script] the loaded script
      #
      def load(name, conn)
        script = Script.load(name, root_path, conn)
        scripts.put(name.to_sym, script)
        script
      end

      #
      # Delete a script from the collection
      #
      # @param [Script, Symbol, String] script the script or script name to delete
      #
      # @return [Script, nil] the deleted script
      #
      def delete(script)
        key = script.is_a?(Script) ? script.name : script.to_sym
        scripts.delete(key)
      end

      #
      # Kill a running Redis script
      #
      # @param [Redis] conn the redis connection
      #
      # @return [String] Redis response
      #
      def kill(conn)
        # Handle both namespaced and non-namespaced Redis connections
        redis = conn.respond_to?(:namespace) ? conn.redis : conn
        redis.script(:kill)
      end

      #
      # Execute a lua script with given name
      #
      # @note this method is recursive if we need to load a lua script
      #   that wasn't previously loaded.
      #
      # @param [Symbol] name the name of the script to execute
      # @param [Redis] conn the redis connection to use for execution
      # @param [Array<String>] keys script keys
      # @param [Array<Object>] argv script arguments
      #
      # @return value from script
      #
      def execute(name, conn, keys: [], argv: [])
        script = fetch(name, conn)
        conn.evalsha(script.sha, keys, argv)
      end

      def count
        scripts.keys.size
      end
    end
  end
end
