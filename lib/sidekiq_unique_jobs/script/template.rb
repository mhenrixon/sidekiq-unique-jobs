# frozen_string_literal: true

module SidekiqUniqueJobs
  # Interface to dealing with .lua files
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  module Script
    class Template
      def initialize(script_path)
        @script_path = script_path
      end

      def render(pathname)
        @partial_templates ||= {}
        ERB.new(File.read(pathname)).result binding
      end

      # helper method to include a lua partial within another lua script
      #
      # @param relative_path [String] the relative path to the script from
      #     `Wolverine.config.script_path`
      def include_partial(relative_path)
        unless @partial_templates.key? relative_path
          @partial_templates[relative_path] = nil
          render(Pathname.new("#{@script_path}/#{relative_path}"))
        end
      end
    end
  end
end
