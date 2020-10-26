require 'gh'
require 'multi_json'

module GH
  # Public: Class wrapping low level Github responses.
  #
  # Delegates safe methods to the parsed body (expected to be an Array or Hash).
  class Response
    include GH::Case, Enumerable
    attr_accessor :headers, :data, :body, :url

    # subset of safe methods that both Array and Hash implement
    extend Forwardable
    def_delegators(:@data, :[], :assoc, :each, :empty?, :flatten, :include?, :index, :inspect, :length,
      :pretty_print, :pretty_print_cycle, :rassoc, :select, :size, :to_a, :values_at)

    # Internal: Initializes a new instance.
    #
    # headers - HTTP headers as a Hash
    # body    - HTTP body as a String
    def initialize(body = "{}", headers = {}, url = nil)
      @url     = url
      @headers = Hash[headers.map { |k,v| [k.downcase, v] }]

      case body
      when nil, ''              then @data = {}
      when respond_to(:to_str)  then @body = body.to_str
      when respond_to(:to_hash) then @data = body.to_hash
      when respond_to(:to_ary)  then @data = body.to_ary
      else raise ArgumentError, "cannot parse #{body.inspect}"
      end

      @body.force_encoding("utf-8") if @body.respond_to? :force_encoding
      @body ||= MultiJson.encode(@data)
      @data ||= MultiJson.decode(@body)
    rescue EncodingError => error
      fail "Invalid encoding in #{url.to_s}, please contact github."
    end

    # Public: Duplicates the instance. Will also duplicate some instance variables to behave as expected.
    #
    # Returns new Response instance.
    def dup
      super.dup_ivars
    end

    # Public: Returns the response body as a String.
    def to_s
      @body.dup
    end

    # Public: Returns true or false indicating whether it supports method.
    def respond_to?(method, *)
      return super unless method.to_s == "to_hash" or method.to_s == "to_ary"
      data.respond_to? method
    end

    # Public: Implements to_hash conventions, please check respond_to?(:to_hash).
    def to_hash
      return method_missing(__method__) unless respond_to? __method__
      @data.dup.to_hash
    end

    # Public: Implements to_ary conventions, please check respond_to?(:to_hash).
    def to_ary
      return method_missing(__method__) unless respond_to? __method__
      @data.dup.to_ary
    end

    # Public: ...
    def to_gh
      self
    end

    # Public: ...
    def ==(other)
      super or @data == other
    end

    protected

    def dup_ivars
      @headers, @data, @body = @headers.dup, @data.dup, @body.dup
      self
    end

    private

    def content_type
      headers['content-type']
    end
  end
end
