guard :rspec, cmd: 'bundle exec rspec', all_on_start: true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard :reek, cli: ['--single-line', '--empty-headings'] do
  watch('config.reek')
  watch(/^lib\/.*\.rb$/)
end
