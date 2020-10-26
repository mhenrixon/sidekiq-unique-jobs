module Gem
  module Release
    class Context
      class Git
        def clean?
          system 'git diff-index --quiet HEAD'
        end

        def remotes
          `git remote`.split("\n")
        end

        def tags
          `git tag`.split("\n")
        end

        def user_name
          str = `git config --get user.name`.strip
          str unless str.empty?
        end

        def user_email
          str = `git config --get user.email`.strip
          str unless str.empty?
        end

        def user_login
          str = `git config --get github.user`.strip
          str.empty? ? user_name : str
        end
      end
    end
  end
end
