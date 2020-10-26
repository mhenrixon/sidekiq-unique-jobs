module GH
  class LinkFollower < Wrapper
    wraps GH::Normalizer
    double_dispatch

    def modify_hash(hash)
      hash = super
      setup_lazy_loading(hash) if hash['_links']
      hash
    rescue Exception => error
      raise Error.new(error, hash)
    end

    private

    def lazy_load(hash, key)
      link = hash['_links'][key]
      { key => self[link['href']] } if link
    rescue Exception => error
      raise Error.new(error, hash)
    end
  end
end