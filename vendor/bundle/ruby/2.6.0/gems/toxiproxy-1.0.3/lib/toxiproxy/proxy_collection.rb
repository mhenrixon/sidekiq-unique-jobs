class Toxiproxy
  # ProxyCollection represents a set of proxies. This allows to easily perform
  # actions on every proxy in the collection.
  #
  # Unfortunately, it doesn't implement all of Enumerable because there's no way
  # to subclass an Array or include Enumerable for the methods to return a
  # Collection instead of an Array (see MRI). Instead, we delegate methods where
  # it doesn't matter and only allow the filtering methods that really make
  # sense on a proxy collection.
  class ProxyCollection
    extend Forwardable

    DELEGATED_METHODS = [:length, :size, :count, :find, :each, :map]
    DEFINED_METHODS   = [:select, :reject, :grep, :down]
    METHODS = DEFINED_METHODS + DELEGATED_METHODS

    def_delegators :@collection, *DELEGATED_METHODS

    def initialize(collection)
      @collection = collection
    end

    # Sets every proxy in the collection as down. For example:
    #
    #   Toxiproxy.grep(/redis/).down { .. }
    #
    # Would simulate every Redis server being down for the duration of the
    # block.
    def down(&block)
      @collection.inject(block) { |nested, proxy|
        -> { proxy.down(&nested) }
      }.call
    end

    # Set an upstream toxic.
    def upstream(toxic, attrs = {})
      toxics = ToxicCollection.new(@collection)
      toxics.upstream(toxic, attrs)
      toxics
    end

    # Set a downstream toxic.
    def downstream(toxic, attrs = {})
      toxics = ToxicCollection.new(@collection)
      toxics.downstream(toxic, attrs)
      toxics
    end
    alias_method :toxicate, :downstream
    alias_method :toxic, :downstream

    def disable
      @collection.each(&:disable)
    end

    def enable
      @collection.each(&:enable)
    end

    # Destroys all toxiproxy's in the collection
    def destroy
      @collection.each(&:destroy)
    end

    def select(&block)
      self.class.new(@collection.select(&block))
    end

    def reject(&block)
      self.class.new(@collection.reject(&block))
    end

    # Grep allows easily selecting a subset of proxies, by returning a
    # ProxyCollection with every proxy name matching the regex passed.
    def grep(regex)
      self.class.new(@collection.select { |proxy|
        proxy.name =~ regex
      })
    end
  end
end
