require 'gh'
require 'timeout'

module GH
  # Public: ...
  class MergeCommit < Wrapper
    wraps GH::Normalizer
    double_dispatch

    def setup(backend, options)
      @ssl = options[:ssl]
      super
    end

    def modify_hash(hash)
      setup_lazy_loading(super)
    rescue Exception => error
      raise Error.new(error, hash)
    end

    private

    def lazy_load(hash, key)
      return unless key =~ /^(merge|head|base)_commit$/ and hash.include? 'mergeable'
      return unless has_merge_commit?(hash)
      fields = pull_request_refs(hash)
      fields['base_commit'] ||= commit_for hash, hash['base']
      fields['head_commit'] ||= commit_for hash, hash['head']
      fields
    rescue Exception => error
      raise Error.new(error, hash)
    end

    def commit_for(from, hash)
      { 'sha' => hash['sha'], 'ref' => hash['ref'],
        '_links' => { 'self' => { 'href' => git_url_for(from, hash['sha']) } } }
    end

    def git_url_for(hash, commitish)
      hash['_links']['self']['href'].gsub(%r{/pulls/(\d+)$}, "/git/#{commitish}")
    end

    def pull_request_refs(hash)
      link     = git_url_for(hash, 'refs/pull/\1')
      commits  = self[link].map do |data|
        ref    = data['ref']
        name   = ref.split('/').last + "_commit"
        object = data['object'].merge 'ref' => ref
        [name, object]
      end
      Hash[commits]
    end

    def has_merge_commit?(hash)
      force_merge_commit(hash)
      hash['mergeable']
    end

    def github_done_checking?(hash)
      case hash['mergeable_state']
      when 'checking'                                                           then false
      when 'unknown'                                                            then hash['merged']
      when 'clean', 'dirty', 'unstable', 'stable', 'blocked', 'behind', 'draft' then true
      else fail "unknown mergeable_state #{hash['mergeable_state'].inspect} for #{url(hash)}"
      end
    end

    def force_merge_commit(hash)
      Timeout.timeout(180) do
        update(hash) until github_done_checking? hash
      end
    rescue TimeoutError
      status = hash['mergeable_state'].inspect
      raise TimeoutError, "gave up waiting for github to check the merge status (current status is #{status})"
    end

    def update(hash)
      hash.merge! backend[url(hash)]
      sleep 0.5
    end

    def url(hash)
      hash['_links']['self']['href']
    end
  end
end
