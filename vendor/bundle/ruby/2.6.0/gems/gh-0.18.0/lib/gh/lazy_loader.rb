require 'gh'

module GH
  # Public: ...
  class LazyLoader < Wrapper
    wraps GH::Normalizer
    double_dispatch

    def modify_hash(hash, loaded = false)
      hash = super(hash)
      link = hash['_links']['self'] unless loaded or hash['_links'].nil?
      setup_lazy_loading(hash, link['href']) if link
      hash
    rescue Exception => error
      raise Error.new(error, hash)
    end

    private

    def lazy_load(hash, key, link)
      modify_hash(backend[link].data, true)
    rescue Exception => error
      raise Error.new(error, hash)
    end
  end
end
