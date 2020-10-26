require 'gem/release/context'

module Gem
  module Release
    module Cmds
      class Runner < Struct.new(:name, :args, :opts, :context)
        def run
          run_cmd
          success
        end

        private

          def success
            context.ui.success "All is good, thanks my friend."
          end

          def run_cmd
            const.new(context, args, opts).run
          end

          def const
            Base[name]
          end

          def args
            super.select { |arg| arg.is_a?(String) && arg[0] != '-' }
          end

          def opts
            @opts ||= except(Base::DEFAULTS.merge(config.merge(super)), :args, :build_args)
          end

          def config
            Context.new.config.for(name.to_sym)
          end

          def context
            @context ||= super || Context.new(opts)
          end

          def except(hash, *keys)
            hash.reject { |key, _| keys.include?(key) }
          end
      end
    end
  end
end
