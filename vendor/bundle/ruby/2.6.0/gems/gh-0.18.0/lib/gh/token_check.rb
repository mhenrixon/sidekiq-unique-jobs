require 'gh/error'
require 'base64'

module GH
  class TokenCheck < Wrapper
    attr_accessor :client_id, :client_secret, :token

    def setup(backend, options)
      @client_secret = options[:client_secret]
      @client_id     = options[:client_id]
      @token         = options[:token]
      @check_token   = true
      super
    end

    def check_token
      return unless @check_token and client_id and client_secret and token
      @check_token = false

      auth_header = "Basic %s" % Base64.encode64("#{client_id}:#{client_secret}").gsub("\n", "")
      http :post, path_for("/applications/#{client_id}/token"), :body => "{\"access_token\": \"#{token}\"}", "Authorization" => auth_header
    rescue GH::Error(:response_status => 404) => error
      raise GH::TokenInvalid, error
    end

    def http(*)
      check_token
      super
    end
  end
end
