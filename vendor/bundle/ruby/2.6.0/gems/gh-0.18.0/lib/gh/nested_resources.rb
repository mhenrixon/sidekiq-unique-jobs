require 'gh'

module GH
  # Public: ...
  class NestedResources < Wrapper
    wraps GH::Normalizer
    double_dispatch

    def modify_hash(hash, loaded = false)
      hash = super(hash)
      link = hash['_links']['self'] unless loaded or hash['_links'].nil?
      set_links hash, Addressable::URI.parse(link['href']) if link
      hash
    end

    def add(hash, link, name, path = name)
      hash["_links"][name] ||= { "href" => nested(link, path) }
    end

    def nested(link, path)
      new_link = link.dup
      if path.start_with? '/'
        new_link.path = path
      else
        new_link.path += path
      end
      new_link
    end

    def set_links(hash, link)
      case link.path
      when '/gists'
        add hash, link, 'public'
        add hash, link, 'starred'
      when %r{^/repos/[^/]+/[^/]+$}
        add hash, link, 'commits', 'git/commits'
        add hash, link, 'refs',    'git/refs'
        add hash, link, 'tags',    'git/tags'
        add hash, link, 'issues'
      when %r{^/repos/[^/]+/[^/]+/issues/\d+$}
        add hash, link, 'comments'
        add hash, link, 'events'
      when '/user'
        add hash, link, 'gists',  '/gists'
        add hash, link, 'issues', '/issues'
      end
    end
  end
end
