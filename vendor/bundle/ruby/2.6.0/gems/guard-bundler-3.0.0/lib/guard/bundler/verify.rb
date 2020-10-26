require 'pathname'

module Guard
  class Bundler < Plugin
    class Verify
      if Gem.win_platform?
        SYMLINK_NEEDED = <<-EOS
  Error: Guard will not detect changes to your Gemfile!

  Solution: move the Gemfile to a watched directory and symlink it, so that
  'Gemfile' is symlinked e.g. to config/Gemfile.

  (See: https://github.com/guard/guard/wiki/Optimizing-for-large-projects)

        EOS
      else
        SYMLINK_NEEDED = <<-EOS
  Error: Guard will not detect changes to your Gemfile!

  Solution: move the Gemfile to a watched directory and symlink it back.

  Example:

    $ mkdir config
    $ git mv Gemfile config # use just 'mv' if this doesn't work
    $ ln -s config/Gemfile .

  and add config to the `directories` statement in your Guardfile.

  (See: https://github.com/guard/guard/wiki/Optimizing-for-large-projects)
        EOS
      end

      def verify!(file)
        watchdirs = Guard::Compat.watched_directories

        gemfile = Pathname.new(file)
        config_dir = gemfile.realpath.dirname
        return if watchdirs.include?(config_dir)

        Compat::UI.error SYMLINK_NEEDED
      end

      def real_path(file)
        verify!(file)
        Pathname.new(file).realpath.relative_path_from(Pathname.pwd).to_s
      end

      def uses_gemspec?(file)
        IO.read(file).lines.map(&:strip).grep(/^gemspec$/).any?
      end
    end
  end
end
