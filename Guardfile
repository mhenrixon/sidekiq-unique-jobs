REEK_ARGS = %w[
  --line-numbers
  --color
  --documentation
  --progress
  --single-line
  --sort-by smelliness
].freeze

RUBOCOP_ARGS = %w[
  -P
  --format fuubar
].freeze

RSPEC_OPTIONS = {
  cmd: "env COV=true bundle exec rspec",
  # cmd_additional_args: "--format documentation",
  failed_mode: :focus,
  all_on_start: false
}

scope group: :tdd
clearing :on
notification :terminal_notifier, app_name: "sidekiq-unique-jobs ::", activate: "com.googlecode.iTerm2" if `uname` =~ /Darwin/

group :tdd, halt_on_fail: true do
  guard :rspec, RSPEC_OPTIONS do
    require "guard/rspec/dsl"
    dsl = Guard::RSpec::Dsl.new(self)

    # RSpec files
    rspec = dsl.rspec
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/integration/#{m[1]}_spec.rb" }
    watch(%r{^spec/support/workers/(.+)\.rb$}) { |m| "spec/workers/#{m[1]}_spec.rb" }
    watch(rspec.spec_helper)  { rspec.spec_dir }
    watch(rspec.spec_support) { rspec.spec_dir }
    watch(rspec.spec_files)

    ruby = dsl.ruby
    dsl.watch_spec_files_for(ruby.lib_files)
  end

  guard :rubocop, all_on_start: false, cli: RUBOCOP_ARGS do
    watch(%r{.+\.rb$})
    watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
  end

  guard :reek, all_on_start: false, cli: REEK_ARGS do
    watch(%r{.+\.rb$})
    watch('.reek')
  end
end

guard :bundler do
  watch('Gemfile')
end
