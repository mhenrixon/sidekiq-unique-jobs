require 'gem/release/support/gem_command'
require 'gem/release/cmds/gemspec'

class Gem::Commands::GemspecCommand < Gem::Command
  include Gem::Release::GemCommand
  self.cmd = :gemspec
end
