require 'gh'

module GH
  # Public: Exposes DSL for stacking wrappers.
  #
  # Examples
  #
  #   api = GH::Stack.build do
  #     use GH::Cache, cache: Rails.cache
  #     use GH::Normalizer
  #     use GH::Remote, username: "admin", password: "admin"
  #   end
  class Stack
    attr_reader :options

    # Public: Generates a new wrapper stack from the given block.
    #
    # options - Hash of options that will be passed to all layers upon initialization.
    #
    # Returns top most Wrapper instance.
    def self.build(options = {}, &block)
      new(&block).build(options)
    end

    # Public: Generates a new Stack instance.
    #
    # options - Hash of options that will be passed to all layers upon initialization.
    #
    # Can be used for easly stacking layers.
    def initialize(options = {}, &block)
      @options, @stack = {}, []
      instance_eval(&block) if block
    end

    # Public: Adds a new layer to the stack.
    #
    # Layer will be wrapped by layers already on the stack.
    def use(klass, options = {})
      @stack << [klass, options]
      self
    end

    # Public: Generates wrapper instances for stack configuration.
    #
    # options - Hash of options that will be passed to all layers upon initialization.
    #
    # Returns top most Wrapper instance.
    def build(options = {})
      @stack.reverse.inject(nil) do |backend, (klass, opts)|
        klass.new backend, @options.merge(opts).merge(options)
      end
    end

    # Public: ...
    def replace(old_class, new_class)
      @stack.map! { |klass, options| [old_class == klass ? new_class : klass, options] }
    end

    alias_method :new, :build
  end
end
