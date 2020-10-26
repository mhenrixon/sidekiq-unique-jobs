require 'gem/release/support/gem_command'
require 'gem/release/cmds/bump'

class Gem::Commands::BumpCommand < Gem::Command
  include Gem::Release::GemCommand
  self.cmd = :bump
end
