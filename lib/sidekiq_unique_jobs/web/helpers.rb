# frozen_string_literal: true

module SidekiqUniqueJobs
  module Web
    module Helpers
      VIEW_PATH = File.expand_path("../web/views", __dir__)

      module_function

      def unique_template(name)
        File.open(File.join(VIEW_PATH, "#{name}.erb")).read
      end

      def digests
        @digests ||= SidekiqUniqueJobs::Digests.new
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

      def relative_time(time)
        stamp = time.getutc.iso8601
        %(<time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{time}</time>)
      end

      def safe_relative_time(time)
        time = parse_time(time)

        relative_time(time)
      end

      def parse_time(time)
        case time
        when Time
          time
        when Integer, Float
          Time.at(time)
        else
          Time.parse(time.to_s)
        end
      end
    end
  end
end
