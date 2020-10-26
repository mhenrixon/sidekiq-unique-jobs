require 'erb'
require 'ostruct'
require 'gem/release/helper/string'

module Gem
  module Release
    class Data < Struct.new(:git, :gem, :opts)
      include Helper::String

      def data
        {
          gem_name:     gem_name,
          gem_path:     gem_path,
          module_names: module_names,
          author:       user_name,
          email:        user_email,
          homepage:     homepage,
          licenses:     licenses,
          summary:      '[summary]',
          description:  '[description]',
          files:        files,
          bin_files:    bin_files
        }
      end

      private

        def module_names
          gem_name.split('-').map { |part| camelize(part) }
        end

        def gem_name
          gem.name || raise('No gem_name given.')
        end

        def gem_path
          gem_name.gsub('-', '/').sub(/_rb$/, '')
        end

        def user_login
          git.user_login || '[your login]'
        end

        def user_name
          git.user_name || '[your name]'
        end

        def user_email
          git.user_email || '[your email]'
        end

        def homepage
          "https://github.com/#{user_login}/#{gem_name}"
        end

        def licenses
          Array(license).join(',').split(',').map(&:upcase)
        end

        def license
          opts[:license] if opts[:license]
        end

        def files
          strategy[:files]
        end

        def bin_files
          strategy[:bin_files] if opts.key?(:bin) ? opts[:bin] : File.directory?('./bin')
        end

        def strategy
          STRATEGIES[(opts[:strategy] || :glob).to_sym] || STRATEGIES[:glob]
        end
    end
  end
end
