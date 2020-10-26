module Gem
  module Release
    module Helper
      module Hash
        MERGER = ->(key, lft, rgt) do
          if lft.is_a?(::Hash) && rgt.is_a?(::Hash)
            lft.merge(rgt, &MERGER)
          else
            rgt
          end
        end

        def deep_merge(hash, other)
          hash.merge(other, &MERGER)
        end

        def symbolize_keys(hash)
          hash.map do |key, obj|
            key = key.respond_to?(:to_sym) ? key.to_sym : key
            obj = symbolize_keys(obj) if obj.is_a?(::Hash)
            [key, obj]
          end.to_h
        end

        def only(hash, *keys)
          hash.select { |key, _| keys.include?(key) }
        end

        def except(hash, *keys)
          hash.reject { |key, _| keys.include?(key) }
        end
      end
    end
  end
end
