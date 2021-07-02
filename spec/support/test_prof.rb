# frozen_string_literal: true

begin
  require "test_prof"
  require "test_prof/recipes/logging"
  require "test_prof/recipes/rspec/sample"

  TestProf.configure do |config|
    config.output_dir = "tmp/test_prof"
    config.timestamps = true
    config.color = true
  end
rescue LoadError
  # Do nothing, we don't have test_prof
end
