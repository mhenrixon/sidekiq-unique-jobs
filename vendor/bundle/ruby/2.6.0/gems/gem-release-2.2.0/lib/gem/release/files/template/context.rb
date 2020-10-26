module Gem
  module Release
    module Files
      class Template
        class Context < OpenStruct
          class Const < Struct.new(:type, :names)
            def define(&block)
              lines = build(names) { |name| "#{type} #{name}" }
              lines << indent(block.call, names.size) if block
              lines += build(names) { |name| 'end' }.reverse
              lines.join("\n")
            end

            def build(names, &block)
              names.map.with_index { |name, ix| indent(block.call(name), ix) }
            end

            def indent(str, level)
              "#{'  ' * level}#{str}"
            end
          end

          def define(type, &block)
            Const.new(type, module_names).define(&block)
          end
        end
      end
    end
  end
end
