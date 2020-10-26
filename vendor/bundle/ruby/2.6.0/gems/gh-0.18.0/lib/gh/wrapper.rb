require 'gh'
require 'addressable/uri'

module GH
  # Public: Simple base class for low level layers.
  # Handy if you want to manipulate resources coming in from Github.
  #
  # Examples
  #
  #   class IndifferentAccess
  #     def [](key) super.tap { |r| r.data.with_indifferent_access! } end
  #   end
  #
  #   gh = IndifferentAccess.new
  #   gh['users/rkh'][:name] # => "Konstantin Haase"
  #
  #   # easy to use in the low level stack
  #   gh = Github.build do
  #     use GH::Cache
  #     use IndifferentAccess
  #     use GH::Normalizer
  #   end
  class Wrapper
    extend Forwardable
    include Case

    # Public: Get wrapped layer.
    attr_reader :backend

    # Public: ...
    attr_reader :options

    # Public: Returns the URI used for sending out web request.
    def_delegator :backend, :api_host

    # Internal: ...
    def_delegator :backend, :http

    # Internal: ...
    def_delegator :backend, :request

    # Public: ...
    def_delegator :backend, :post

    # Public: ...
    def_delegator :backend, :delete

    # Public: ...
    def_delegator :backend, :head

    # Public: ...
    def_delegator :backend, :patch

    # Public: ...
    def_delegator :backend, :put

    # Public: ...
    def_delegator :backend, :fetch_resource

    # Public: ...
    def_delegator :backend, :in_parallel

    # Public: ...
    def_delegator :backend, :in_parallel?

    # Public: ...
    def_delegator :backend, :full_url

    # Public: ...
    def_delegator :backend, :path_for

    # Public: Retrieves resources from Github.
    def self.[](key)
      new[key]
    end

    # Public: Retrieves resources from Github.
    #
    # By default, this method is delegated to the next layer on the stack
    # and modify is called.
    def [](key)
      generate_response key, fetch_resource(key)
    end

    # Internal: ...
    def generate_response(key, resource)
      modify backend.generate_response(key, resource)
    end

    # Internal: Get/set default layer to wrap when creating a new instance.
    def self.wraps(klass = nil)
      @wraps = klass if klass
      @wraps ||= Remote
    end

    # Public: Initialize a new Wrapper.
    #
    # backend - layer to be wrapped
    # options - config options
    def initialize(backend = nil, options = {})
      backend, @options = normalize_options(backend, options)
      @options.each_pair { |key, value| public_send("#{key}=", value) if respond_to? "#{key}=" }
      setup(backend, @options)
    end

    # Public: Set wrapped layer.
    def backend=(layer)
      reset if backend
      layer.frontend = self
      @backend = layer
    end

    # Internal: ...
    def frontend=(value)
      @frontend = value
    end

    # Internal: ...
    def frontend
      @frontend ? @frontend.frontend : self
    end

    # Public: ...
    def inspect
      "#<#{self.class}: #{backend.inspect}>"
    end

    # Internal: ...
    def prefixed(key)
      prefix + "#" + identifier(key)
    end

    # Public: ...
    def reset
      backend.reset if backend
    end

    # Public: ...
    def load(data)
      modify backend.load(data)
    end

    private

    def identifier(key)
      backend.prefixed(key)
    end

    def prefix
      self.class.name
    end

    def self.double_dispatch
      define_method(:modify) { |data| double_dispatch(data) }
    end

    def double_dispatch(data)
      case data
      when respond_to(:to_gh)   then modify_response(data)
      when respond_to(:to_hash) then modify_hash(data)
      when respond_to(:to_ary)  then modify_array(data)
      when respond_to(:to_str)  then modify_string(data)
      when respond_to(:to_int)  then modify_integer(data)
      else modify_unknown data
      end
    rescue Exception => error
      raise Error.new(error, data)
    end

    def modify_response(response)
      result = double_dispatch response.data
      result.respond_to?(:to_gh) ? result.to_gh : Response.new(result, response.headers, response.url)
    end

    def modify(data, *)
      data
    rescue Exception => error
      raise Error.new(error, data)
    end

    def modify_array(array)
      array.map { |e| modify(e) }
    end

    def modify_hash(hash, &block)
      corrected = {}
      hash.each_pair { |k,v| corrected[k] = modify(v) }
      corrected.default_proc = hash.default_proc if hash.default_proc
      corrected
    end

    alias modify_string   modify
    alias modify_integer  modify
    alias modify_unknown  modify

    def setup(backend, options)
      self.backend = Wrapper === backend ? backend : self.class.wraps.new(backend, options)
    end

    def normalize_options(backend, options)
      backend, options = nil, backend if Hash === backend
      options ||= {}
      backend ||= options[:backend] || options[:api_url] || 'https://api.github.com'
      [backend, options]
    end

    def setup_default_proc(hash, &block)
      old_proc = hash.default_proc
      hash.default_proc = proc do |hash, key|
        value = old_proc.call(hash, key) if old_proc
        value = block[hash, key] if value.nil?
        value
      end
    end

    def setup_lazy_loading(hash, *args)
      loaded = false
      setup_default_proc hash do |hash, key|
        next if loaded
        fields = lazy_load(hash, key, *args)
        if fields
          modify_hash fields
          hash.merge! fields
          loaded = true
          fields[key]
        end
      end
      hash
    end
  end
end
