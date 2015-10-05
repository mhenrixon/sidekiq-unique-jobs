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
begin
  require 'active_support/core_ext/string/inflections'
rescue LoadError
  class String
    # File activesupport/lib/active_support/inflector/methods.rb, line 178
    def classify
      camelize(singularize(sub(/.*\./, '')))
    end unless ''.respond_to?(:classify)

    # File activesupport/lib/active_support/inflector/methods.rb, line 67
    def camelize(uppercase_first_letter = true)
      string = self
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      else
        string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
      end
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}" }
      string.gsub!(/\//, '::')
      string
    end unless ''.respond_to?(:camelize)
  end
end
