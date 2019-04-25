# frozen_string_literal: true

require "timeasure"

RSpec.configure do |config|
  config.before(:suite) do
    Timeasure.configure do |configuration|
      configuration.enable_timeasure_proc = lambda { false }
    end
  end

  config.before(:each, profile: true) do
    Timeasure.configure do |configuration|
      configuration.enable_timeasure_proc = lambda { true }
    end
  end
end
