module SidekiqUniqueJobs
  begin
    require 'active_support/core_ext/hash/keys'
    require 'active_support/core_ext/hash/deep_merge'
  rescue LoadError
    class Hash
      def slice(*keys)
        keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
        keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if key?(k) }
      end unless {}.respond_to?(:slice)

      def slice!(*keys)
        keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
        omit = slice(*self.keys - keys)
        hash = slice(*keys)
        hash.default      = default
        hash.default_proc = default_proc if default_proc
        replace(hash)
        omit
      end unless {}.respond_to?(:slice!)
    end
  end
end
