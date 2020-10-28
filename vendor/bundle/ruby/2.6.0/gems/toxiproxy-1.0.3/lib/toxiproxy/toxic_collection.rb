class Toxiproxy
  class ToxicCollection
    extend Forwardable

    attr_accessor :toxics
    attr_reader :proxies

    def_delegators :@toxics, :<<, :find

    def initialize(proxies)
      @proxies = proxies
      @toxics = []
    end

    def apply(&block)
      names = toxics.group_by { |t| [t.name, t.proxy.name] }
      dups  = names.values.select { |toxics| toxics.length > 1 }
      if !dups.empty?
        raise ArgumentError, "There are two toxics with the name #{dups.first[0]} for proxy #{dups.first[1]}, please override the default name (<type>_<direction>)"
      end

      begin
        @toxics.each(&:save)
        yield
      ensure
        @toxics.each(&:destroy)
      end
    end

    def upstream(type, attrs = {})
      proxies.each do |proxy|
        toxics << Toxic.new(
          name: attrs.delete('name') || attrs.delete(:name),
          type: type,
          proxy: proxy,
          stream: :upstream,
          toxicity: attrs.delete('toxicitiy') || attrs.delete(:toxicity),
          attributes: attrs
        )
      end
      self
    end

    def downstream(type, attrs = {})
      proxies.each do |proxy|
        toxics << Toxic.new(
          name: attrs.delete('name') || attrs.delete(:name),
          type: type,
          proxy: proxy,
          stream: :downstream,
          toxicity: attrs.delete('toxicitiy') || attrs.delete(:toxicity),
          attributes: attrs
        )
      end
      self
    end
    alias_method :toxic, :downstream
    alias_method :toxicate, :downstream
  end
end
