require 'net/http'
require 'uri'

module Gem
  module Release
    module Helper
      module Http
        class Client < Struct.new(:method, :url, :body, :headers)
          def request
            req = const.new(uri.request_uri, headers)
            req.body = body if body
            resp = client.request(req)
            [resp.code.to_i, resp.body]
          end

          private

            def uri
              @uri ||= URI.parse(url)
            end

            def client
              http_client = Net::HTTP.new(uri.host, uri.port)
              http_client.use_ssl = (uri.scheme == 'https')
              http_client
            end

            def const
              Net::HTTP.const_get(method.to_s.capitalize)
            end
        end

        def post(url, body = nil, headers = {})
          Client.new(:post, url, body, headers).request
        end
      end
    end
  end
end
