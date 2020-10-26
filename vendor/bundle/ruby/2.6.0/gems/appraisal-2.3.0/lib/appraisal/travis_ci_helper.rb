require "appraisal/appraisal_file"
require "yaml"

module Appraisal
  class TravisCIHelper
    NO_CONFIGURATION_WARNING = <<-WARNING.strip.gsub(/\s+/, " ")
      Note: Run `appraisal generate --travis` to generate Travis CI
      configuration.
    WARNING

    INVALID_CONFIGURATION_WARNING = <<-WARNING.strip.gsub(/\s+/, " ")
      Warning: Your gemfiles directive in .travis.yml is incorrect. Run
      `appraisal generate --travis` to get the correct configuration.
    WARNING

    # @see http://docs.travis-ci.com/user/languages/ruby/
    GEMFILES_CONFIGURATION_KEY = "gemfile".freeze

    def self.display_instruction
      puts "# Put this in your .travis.yml"
      puts "#{GEMFILES_CONFIGURATION_KEY}:"

      AppraisalFile.each do |appraisal|
        puts "  - #{appraisal.relative_gemfile_path}"
      end
    end

    def self.validate_configuration_file
      ConfigurationValidator.new.validate
    end

    class ConfigurationValidator
      CONFIGURATION_FILE = ".travis.yml"

      def validate
        if has_configuration_file?
          if has_no_gemfiles_configuration?
            $stderr.puts(NO_CONFIGURATION_WARNING)
          elsif has_invalid_gemfiles_configuration?
            $stderr.puts(INVALID_CONFIGURATION_WARNING)
          end
        end
      end

      private

      def has_configuration_file?
        File.exist?(CONFIGURATION_FILE)
      end

      def has_no_gemfiles_configuration?
        !(configuration && configuration.has_key?(GEMFILES_CONFIGURATION_KEY))
      end

      def has_invalid_gemfiles_configuration?
        if configuration && configuration[GEMFILES_CONFIGURATION_KEY]
          appraisal_paths =
            AppraisalFile.new.appraisals.map(&:relative_gemfile_path).sort
          travis_gemfile_paths = configuration[GEMFILES_CONFIGURATION_KEY].sort
          appraisal_paths != travis_gemfile_paths
        end
      end

      def configuration
        YAML.load_file(CONFIGURATION_FILE) rescue nil
      end
    end
  end
end
