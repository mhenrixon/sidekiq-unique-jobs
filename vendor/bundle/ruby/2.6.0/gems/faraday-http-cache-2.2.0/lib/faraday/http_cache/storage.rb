# frozen_string_literal: true
require 'json'
require 'digest/sha1'

module Faraday
  class HttpCache < Faraday::Middleware
    # Internal: A wrapper around an ActiveSupport::CacheStore to store responses.
    #
    # Examples
    #
    #   # Creates a new Storage using a MemCached backend from ActiveSupport.
    #   mem_cache_store = ActiveSupport::Cache.lookup_store(:mem_cache_store, ['localhost:11211'])
    #   Faraday::HttpCache::Storage.new(store: mem_cache_store)
    #
    #   # Reuse some other instance of an ActiveSupport::Cache::Store object.
    #   Faraday::HttpCache::Storage.new(store: Rails.cache)
    #
    #   # Creates a new Storage using Marshal for serialization.
    #   Faraday::HttpCache::Storage.new(store: Rails.cache, serializer: Marshal)
    class Storage
      # Public: Gets the underlying cache store object.
      attr_reader :cache

      # Internal: Initialize a new Storage object with a cache backend.
      #
      # :logger     - A Logger object to be used to emit warnings.
      # :store      - An cache store object that should respond to 'read',
      #              'write', and 'delete'.
      # :serializer - A serializer object that should respond to 'dump'
      #               and 'load'.
      def initialize(store: nil, serializer: nil, logger: nil)
        @cache = store || MemoryStore.new
        @serializer = serializer || JSON
        @logger = logger
        assert_valid_store!
      end

      # Internal: Store a response inside the cache.
      #
      # request  - A Faraday::HttpCache::::Request instance of the executed HTTP
      #            request.
      # response - The Faraday::HttpCache::Response instance to be stored.
      #
      # Returns nothing.
      def write(request, response)
        key = cache_key_for(request.url)
        entry = serialize_entry(request.serializable_hash, response.serializable_hash)

        entries = cache.read(key) || []
        entries = entries.dup if entries.frozen?

        entries.reject! do |(cached_request, cached_response)|
          response_matches?(request, deserialize_object(cached_request), deserialize_object(cached_response))
        end

        entries << entry

        cache.write(key, entries)
      rescue ::Encoding::UndefinedConversionError => e
        warn "Response could not be serialized: #{e.message}. Try using Marshal to serialize."
        raise e
      end

      # Internal: Attempt to retrieve an stored response that suits the incoming
      # HTTP request.
      #
      # request  - A Faraday::HttpCache::::Request instance of the incoming HTTP
      #            request.
      # klass    - The Class to be instantiated with the stored response.
      #
      # Returns an instance of 'klass'.
      def read(request, klass: Faraday::HttpCache::Response)
        cache_key = cache_key_for(request.url)
        entries = cache.read(cache_key)
        response = lookup_response(request, entries)

        if response
          klass.new(response)
        end
      end

      def delete(url)
        cache_key = cache_key_for(url)
        cache.delete(cache_key)
      end

      private

      # Internal: Retrieve a response Hash from the list of entries that match
      # the given request.
      #
      # request  - A Faraday::HttpCache::::Request instance of the incoming HTTP
      #            request.
      # entries  - An Array of pairs of Hashes (request, response).
      #
      # Returns a Hash or nil.
      def lookup_response(request, entries)
        if entries
          entries = entries.map { |entry| deserialize_entry(*entry) }
          _, response = entries.find { |req, res| response_matches?(request, req, res) }
          response
        end
      end

      # Internal: Check if a cached response and request matches the given
      # request.
      #
      # request         - A Faraday::HttpCache::::Request instance of the
      #                   current HTTP request.
      # cached_request  - The Hash of the request that was cached.
      # cached_response - The Hash of the response that was cached.
      #
      # Returns true or false.
      def response_matches?(request, cached_request, cached_response)
        request.method.to_s == cached_request[:method].to_s &&
          vary_matches?(cached_response, request, cached_request)
      end

      def vary_matches?(cached_response, request, cached_request)
        headers = Faraday::Utils::Headers.new(cached_response[:response_headers])
        vary = headers['Vary'].to_s

        vary.empty? || (vary != '*' && vary.split(/[\s,]+/).all? do |header|
          request.headers[header] == cached_request[:headers][header]
        end)
      end

      def serialize_entry(*objects)
        objects.map { |object| serialize_object(object) }
      end

      def serialize_object(object)
        @serializer.dump(object)
      end

      def deserialize_entry(*objects)
        objects.map { |object| deserialize_object(object) }
      end

      def deserialize_object(object)
        @serializer.load(object).each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = value
        end
      end

      # Internal: Computes the cache key for a specific request, taking in
      # account the current serializer to avoid cross serialization issues.
      #
      # url - The request URL.
      #
      # Returns a String.
      def cache_key_for(url)
        prefix = (@serializer.is_a?(Module) ? @serializer : @serializer.class).name
        Digest::SHA1.hexdigest("#{prefix}#{url}")
      end

      # Internal: Checks if the given cache object supports the
      # expect API ('read' and 'write').
      #
      # Raises an 'ArgumentError'.
      #
      # Returns nothing.
      def assert_valid_store!
        unless cache.respond_to?(:read) && cache.respond_to?(:write) && cache.respond_to?(:delete)
          raise ArgumentError.new("#{cache.inspect} is not a valid cache store as it does not responds to 'read', 'write' or 'delete'.")
        end
      end

      def warn(message)
        @logger.warn(message) if @logger
      end
    end

    # Internal: A Hash based store to be used by the 'Storage' class
    # when a 'store' is not provided for the middleware setup.
    class MemoryStore
      def initialize
        @cache = {}
      end

      def read(key)
        @cache[key]
      end

      def delete(key)
        @cache.delete(key)
      end

      def write(key, value)
        @cache[key] = value
      end
    end
  end
end
