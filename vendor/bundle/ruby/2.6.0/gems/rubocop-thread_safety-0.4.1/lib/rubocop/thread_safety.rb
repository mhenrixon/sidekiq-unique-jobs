# frozen_string_literal: true

module RuboCop
  # RuboCop::ThreadSafety detects some potential thread safety issues.
  module ThreadSafety
    PROJECT_ROOT = Pathname.new(File.expand_path('../../', __dir__))
    CONFIG_DEFAULT = PROJECT_ROOT.join('config', 'default.yml').freeze
    CONFIG = YAML.safe_load(CONFIG_DEFAULT.read).freeze

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)
  end
end
