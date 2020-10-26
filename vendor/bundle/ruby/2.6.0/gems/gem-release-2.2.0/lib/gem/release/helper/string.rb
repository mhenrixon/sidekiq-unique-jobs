module Gem
  module Release
    module Helper
      class Wrapper < Struct.new(:str, :width)
        MARKDOWN = /^(```|\*|-)/

        def apply
          paras = str.split("\n\n")
          paras.map { |para| wrap_paragraph(para) }.join("\n\n")
        end

        private

          def wrap_paragraph(str)
            return str if str =~ MARKDOWN
            wrap_lines(str.split("\n", width).join(' '))
          end

          def wrap_lines(str)
            str.split("\n\n").map do |str|
              str.size > width ? str.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip : str
            end.join("\n")
          end
      end

      module String
        def camelize(str)
          str.to_s.split(/[^a-z0-9]/i).map { |str| str.capitalize }.join
        end

        def underscore(str)
          str.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            downcase
        end

        def wrap(str, width)
          Wrapper.new(str, width).apply
        end
      end
    end
  end
end
