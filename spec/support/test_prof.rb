# frozen_string_literal: true

begin
  require "test_prof"

  TestProf.configure do |config|
    # the directory to put artifacts (reports) in ('tmp/test_prof' by default)
    config.output_dir = "tmp/test_prof"

    # use unique filenames for reports (by simply appending current timestamp)
    config.timestamps = true

    # color output
    config.color = true
  end
rescue LoadError # rubocop:disable Lint/SuppressedException
  # Do nothing, we don't have test_prof
end
