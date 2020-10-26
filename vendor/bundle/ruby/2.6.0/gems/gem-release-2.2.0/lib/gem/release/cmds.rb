require 'gem/release/cmds/bootstrap'
require 'gem/release/cmds/bump'
require 'gem/release/cmds/gemspec'
require 'gem/release/cmds/github'
require 'gem/release/cmds/release'
require 'gem/release/cmds/runner'
require 'gem/release/cmds/tag'

module Gem
  module Release
    module Cmds
      def self.[](cmd)
        Base[cmd]
      end
    end
  end
end
