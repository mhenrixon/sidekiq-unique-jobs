require 'gh'
require 'time'

module GH
  # Public: A Wrapper class that deals with normalizing Github responses.
  class Normalizer < Wrapper
    def generate_response(key, response)
      result = super
      links(result)['self'] ||= { 'href' => frontend.full_url(key).to_s } if result.respond_to? :to_hash
      result
    end

    private

    double_dispatch

    def links(hash)
      hash = hash.data if hash.respond_to? :data
      hash["_links"] ||= {}
    end

    def set_link(hash, type, href)
      links(hash)[type] = {"href" => href}
    end

    def modify_response(response)
      response      = response.dup
      response.data = modify response.data
      response
    end

    def modify_hash(hash)
      corrected = {}
      corrected.default_proc = hash.default_proc if hash.default_proc

      hash.each_pair do |key, value|
        key = modify_key(key, value)
        next if modify_url(corrected, key, value)
        next if modify_time(corrected, key, value)
        corrected[key] = modify(value)
      end

      modify_user(corrected)
      corrected
    end

    TIME_KEYS    = %w[date timestamp committed_at created_at merged_at closed_at datetime time]
    TIME_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\S*$/

    def modify_time(hash, key, value)
      return unless TIME_KEYS.include? key or TIME_PATTERN === value
      should_be = key == 'timestamp' ? 'date' : key
      raise ArgumentError if RUBY_VERSION < "1.9" and value == "" # TODO: remove this line. duh.
      time = Time.at(value) rescue Time.parse(value.to_s)
      hash[should_be] = time.utc.xmlschema if time
    rescue ArgumentError, TypeError
      hash[should_be] = value
    end

    def modify_user(hash)
      hash['owner']  ||= hash.delete('user') if hash['created_at']   and hash['user']
      hash['author'] ||= hash.delete('user') if hash['committed_at'] and hash['user']

      hash['committer'] ||= hash['author']    if hash['author']
      hash['author']    ||= hash['committer'] if hash['committer']

      modify_user_fields hash['owner']
      modify_user_fields hash['user']
    end

    def modify_user_fields(hash)
      return unless Hash === hash
      hash['login'] = hash.delete('name') if hash['name']
      set_link hash, 'self', "users/#{hash['login']}" unless links(hash).include? 'self'
    end

    def modify_url(hash, key, value)
      case key
      when "blog"
        set_link(hash, key, value)
      when "url"
        type = value.to_s.start_with?(api_host.to_s) ? "self" : "html"
        set_link(hash, type, value)
      when /^(.+)_url$/
        set_link(hash, $1, value)
      when "config"
        hash[key] = value
      end
    end

    def modify_key(key, value = nil)
      case key
      when 'gravatar_url'               then 'avatar_url'
      when 'org'                        then 'organization'
      when 'orgs'                       then 'organizations'
      when 'username'                   then 'login'
      when 'repo'                       then 'repository'
      when 'repos'                      then modify_key('repositories', value)
      when /^repos?_(.*)$/              then "repository_#{$1}"
      when /^(.*)_repo$/                then "#{$1}_repository"
      when /^(.*)_repos$/               then "#{$1}_repositories"
      when 'commit', 'commit_id', 'id'  then value.to_s =~ /^\w{40}$/ ? 'sha' : key
      when 'comments'                   then Numeric === value ? 'comment_count'    : key
      when 'forks'                      then Numeric === value ? 'fork_count'       : key
      when 'repositories'               then Numeric === value ? 'repository_count' : key
      when /^(.*)s_count$/              then "#{$1}_count"
      else key
      end
    end
  end
end
