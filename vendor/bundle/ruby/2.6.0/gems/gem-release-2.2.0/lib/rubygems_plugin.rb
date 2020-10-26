require 'gem/release'
require 'rubygems/command_manager'

require 'rubygems/commands/bootstrap_command'
require 'rubygems/commands/bump_command'
require 'rubygems/commands/gemspec_command'
require 'rubygems/commands/release_command'
require 'rubygems/commands/tag_command'

Gem::CommandManager.instance.register_command :bootstrap
Gem::CommandManager.instance.register_command :bump
Gem::CommandManager.instance.register_command :gemspec
Gem::CommandManager.instance.register_command :release
Gem::CommandManager.instance.register_command :tag
