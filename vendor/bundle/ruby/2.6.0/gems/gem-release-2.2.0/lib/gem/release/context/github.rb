require 'json'
require 'gem/release/helper/http'
require 'gem/release/version'

module Gem
  module Release
    class Context
      class Github
        include Helper::Http

        URL = 'https://api.github.com/repos/%s/releases'

        MSGS = {
          error: 'GitHub returned %s (body: %p)'
        }.freeze

        attr_reader :repo, :data

        def initialize(repo, data)
          @repo = repo
          @data = data
        end

        def release
          # Create a release
          # https://developer.github.com/v3/repos/releases/#create-a-release
          resp = post(url, body, headers)
          status, body = resp
          # success status code is 201 (created) not 200 (ok)
          raise Abort, MSGS.fetch(:error) % [status, body] unless status == 201
        end

        private

          def url
            URL % repo
          end

          def body
            JSON.dump(
              tag_name: data[:tag_name],
              name: data[:name],
              body: data[:descr],
              prerelease: pre?(data[:version])
            )
          end

          def headers
            {
              'User-Agent'    => "gem-release/v#{::Gem::Release::VERSION}",
              'Content-Type'  => 'text/json',
              'Authorization' => "token #{data[:token]}",
            }
          end

          def pre?(version)
            Version::Number.new(version).pre?
          end
      end
    end
  end
end
