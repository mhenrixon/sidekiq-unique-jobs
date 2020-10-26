require 'gem/release/support/gem_command'
require 'gem/release/cmds/release'

class Gem::Commands::ReleaseCommand < Gem::Command
  include Gem::Release::GemCommand
  self.cmd = :release
end
