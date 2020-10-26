require "shellwords"

module Appraisal
  # Executes commands with a clean environment
  class Command
    BUNDLER_ENV_VARS = %w(RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE).freeze

    attr_reader :command, :env, :gemfile, :original_env

    def initialize(command, options = {})
      @gemfile = options[:gemfile]
      @env = options.fetch(:env, {})
      @command = command_starting_with_bundle(command)
      @original_env = {}
    end

    def run
      with_clean_env { ensure_bundler_is_available }
      announce

      with_clean_env do
        env.each_pair do |key, value|
          ENV[key] = value
        end

        unless Kernel.system(command_as_string)
          exit(1)
        end
      end
    end

    private

    def with_clean_env
      unset_bundler_env_vars
      ENV['BUNDLE_GEMFILE'] = gemfile
      ENV['APPRAISAL_INITIALIZED'] = '1'
      yield
    ensure
      restore_env
    end

    def ensure_bundler_is_available
      version = Utils.bundler_version
      unless system %(gem list -i bundler -v #{version})
        puts ">> Reinstall Bundler into #{ENV["GEM_HOME"]}"

        unless system "gem install bundler --version #{version}"
          puts
          puts <<-ERROR.strip.gsub(/\s+/, " ")
            Bundler installation failed.
            Please try running:
              `GEM_HOME="#{ENV["GEM_HOME"]}" gem install bundler --version #{version}`
            manually.
          ERROR
          exit(1)
        end
      end
    end

    def announce
      if gemfile
        puts ">> BUNDLE_GEMFILE=#{gemfile} #{command_as_string}"
      else
        puts ">> #{command_as_string}"
      end
    end

    def unset_bundler_env_vars
      BUNDLER_ENV_VARS.each do |key|
        original_env[key] = ENV[key]
        ENV[key] = nil
      end
    end

    def restore_env
      original_env.each { |key, value| ENV[key] = value }
    end

    def command_starts_with_bundle?(original_command)
      if original_command.is_a?(Array)
        original_command.first =~ /^bundle/
      else
        original_command =~ /^bundle/
      end
    end

    def command_starting_with_bundle(original_command)
      if command_starts_with_bundle?(original_command)
        original_command
      else
        %w(bundle exec) + original_command
      end
    end

    def command_as_string
      if command.is_a?(Array)
        Shellwords.join(command)
      else
        command
      end
    end
  end
end
