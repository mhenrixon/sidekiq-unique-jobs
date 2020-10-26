require 'gem/release/helper'
require 'gem/release/helper/hash'
require 'gem/release/helper/string'
require 'gem/release/support/registry'

module Gem
  module Release
    module Cmds
      class Base < Struct.new(:context, :args, :opts)
        include Helper, Helper::Hash, Helper::String, Registry

        class << self
          include Helper::String

          def inherited(cmd)
            cmd.register underscore(cmd.name.split('::').last)
          end

          def arg(name, summary)
            args << [name, summary]
          end

          def args
            @args ||= []
          end

          def opt(*args, &block)
            opts << [args, block]
          end

          def opts
            @opts ||= superclass != self.class && superclass.respond_to?(:opts) ? superclass.opts.dup : []
          end

          def descr(opt)
            descr = self::DESCR[opt]
            descr = "#{descr} (default: #{default(opt)})" if default(opt)
            descr
          end

          def default(opt)
            Base::DEFAULTS[opt] || self::DEFAULTS[opt]
          end

          def usage(usage = nil)
            usage ? @usage = usage : @usage || '[usage]'
          end

          WIDTH = 70

          def summary(summary = nil)
            summary ? @summary = wrap(summary, WIDTH) : @summary || '[summary]'
          end

          def description(description = nil)
            description ? @description = wrap(description, WIDTH) : @description
          end
        end

        DEFAULTS = {
          color:   true,
          pretend: false,
          quiet:   false
        }.freeze

        opt '--[no-]color' do |value|
          opts[:color] = value
        end

        opt '--pretend' do
          opts[:pretend] = true
        end

        opt '--quiet' do
          opts[:quiet] = true
        end

        attr_reader :gem

        def initialize(context, args, opts)
          opts = defaults.merge(opts)
          super
        end

        def in_dirs
          context.in_dirs(args, opts) do |name|
            @gem = Context::Gem.new(name)
            yield
          end
        end

        def in_gem_dirs
          context.in_gem_dirs(args, opts) do |name|
            @gem = Context::Gem.new(name)
            yield
          end
        end

        def pretend?
          !!opts[:pretend]
        end

        def quiet?
          opts[:quiet] || opts[:silent]
        end

        def opts
          @opts ||= config.merge(super)
        end

        def config
          context.config.for(registry_key)
        end

        def defaults
          self.class.const_defined?(:DEFAULTS) ? self.class::DEFAULTS : {}
        end
      end
    end
  end
end
