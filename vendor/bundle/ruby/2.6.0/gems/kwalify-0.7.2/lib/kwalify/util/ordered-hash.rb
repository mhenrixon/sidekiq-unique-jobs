###
### $Rev$
### 0.7.2
### $COPYRIGHT$
###

module Kwalify

  module Util

    class OrderedHash < Hash

      def initialize(*args, &block)
        super
        @_keys = []
      end

      alias __set__ []=

      def put(key, val)
        @_keys << key unless self.key?(key)
        __set__(key, val)
      end

      def add(key, val)
        @_keys.delete_at(@_keys.index(key)) if self.key?(key)
        @_keys << key
        __set__(key, val)
      end

      alias []= put
      #alias []= add

      def keys
        return @_keys.dup
      end

      def values
        return @_keys.collect {|key| self[key] }
      end

      def delete(key)
        @_keys.delete_at(@_keys.index(key)) if self.key?(key)
        super
      end

      def each
        @_keys.each do |key|
          yield key, self[key]
        end
      end

    end

  end

end
