# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Lock provides access to information about a lock
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  #
  class Lock
    #
    # Class Info provides information about a lock
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Info < Redis::String
      #
      # Returns the value for this key as a hash
      #
      #
      # @return [Hash]
      #
      def value
        @value ||= load_json(super)
      end

      #
      # Quick access to the hash members for the value
      #
      # @param [String, Symbol] key the key who's value to retrieve
      #
      # @return [Object]
      #
      def [](key)
        value[key.to_s] if value.is_a?(Hash)
      end

      #
      # Writes the lock info to redis
      #
      # @param [Hash] obj <description>
      #
      # @return [<type>] <description>
      #
      def set(obj)
        return unless SidekiqUniqueJobs.config.use_lock_info
        raise InvalidArgument, "obj needs to be a hash" unless obj.is_a?(Hash)

        @value = obj
        super(dump_json(obj))
        value
      end
    end
  end
end
