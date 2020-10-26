require 'gh'
require 'thread'
require 'backports/basic_object' unless defined? BasicObject

module GH
  # Public: ...
  class Parallel < Wrapper
    attr_accessor :parallelize

    class Dummy < BasicObject
      attr_accessor :__delegate__
      def method_missing(*args)
        ::Kernel.raise ::RuntimeError, "response not yet loaded" if __delegate__.nil?
        __delegate__.__send__(*args)
      end
    end

    def setup(*)
      @parallelize = true if @parallelize.nil?
      @in_parallel = false
      @mutex       = Mutex.new
      @queue       = []
      super
    end

    def generate_response(key, response)
      return super unless in_parallel?
      dummy = Dummy.new
      @mutex.synchronize { @queue << [dummy, key, response] }
      dummy
    end

    def in_parallel
      return yield if in_parallel? or not @parallelize
      was, @in_parallel = @in_parallel, true
      result = nil
      connection.in_parallel { result = yield }
      @mutex.synchronize do
        @queue.each { |dummy, key, response| dummy.__delegate__ = backend.generate_response(key, response) }
        @queue.clear
      end
      result
    ensure
      @in_parallel = was unless was.nil?
    end

    def in_parallel?
      @in_parallel
    end

    def connection
      @connection ||= begin
        layer = backend
        layer = layer.backend until layer.respond_to? :connection
        layer.connection
      end
    end
  end
end
