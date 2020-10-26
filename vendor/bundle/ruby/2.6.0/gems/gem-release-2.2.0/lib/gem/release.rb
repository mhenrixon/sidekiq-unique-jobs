module Gem
  module Release
    Abort = Class.new(StandardError)

    STRATEGIES = {
      git:  {
        files: '`git ls-files app lib`.split("\n")',
        bin_files: '`git ls-files bin`.split("\n").map { |f| File.basename(f) }',
      },
      glob: {
        files: "Dir.glob('{bin/*,lib/**/*,[A-Z]*}')",
        bin_files: "Dir.glob('bin/*').map { |f| File.basename(f) }",
      }
    }.freeze
  end
end

require 'gem/release/cmds'
require 'gem/release/config'
