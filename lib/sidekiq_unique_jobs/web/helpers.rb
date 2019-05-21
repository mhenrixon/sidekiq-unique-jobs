# frozen_string_literal: true

module SidekiqUniqueJobs
  module Web
    module Helpers
      VIEW_PATH = File.expand_path("../web/views", __dir__)

      def unique_template(name)
        File.open(File.join(VIEW_PATH, "#{name}.erb")).read
      end

      def digests
        @digests ||= Redis::Digests.new
      end

      SAFE_CPARAMS = %w[cursor prev_cursor].freeze

      def cparams(options)
        # stringify
        options.keys.each do |key|
          options[key.to_s] = options.delete(key)
        end

        params.merge(options).map do |key, value|
          next unless SAFE_CPARAMS.include?(key)

          "#{key}=#{CGI.escape(value.to_s)}"
        end.compact.join("&")
      end

      def redirect_to(subpath)
        if respond_to?(:to)
          # Sinatra-based web UI
          redirect to(subpath)
        else
          # Non-Sinatra based web UI (Sidekiq 4.2+)
          redirect "#{root_path}#{subpath}"
        end
      end

      def safe_relative_time(time)
        time =
          case time
          when Integer
            Time.at(time)
          when Float
            Time.at(time)
          else
            Time.parse(time.to_s)
          end

        relative_time(time)
      end

      def safe_time(time)
        time =
          case time
          when Integer
            Time.at(time)
          when Float
            Time.at(time)
          else
            Time.parse(time.to_s)
          end

        %{<time class="ltr" dir="ltr" title="#{time}" datetime="#{time}">#{time}</time>}
      end
    end
  end
end
