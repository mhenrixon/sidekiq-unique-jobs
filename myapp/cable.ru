# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require File.expand_path("config/environment", __dir__)
Rails.application.eager_load!

run ActionCable.server
