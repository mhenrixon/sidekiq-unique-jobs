# frozen_string_literal: true

module SidekiqUniqueJobs
  module Web
    module Helpers
      VIEW_PATH = File.expand_path('../../web/views', __FILE__)

      def filtering(pattern, count)
        SidekiqUniqueJobs::Util.keys(pattern, count)
      end

      def unique_template(name)
        File.open(File.join(VIEW_PATH, "#{name}.erb")).read
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
        time = if time.is_a?(Numeric)
                 Time.at(time)
               else
                 Time.parse(time)
               end

        relative_time(time)
      end
    end
  end
end
