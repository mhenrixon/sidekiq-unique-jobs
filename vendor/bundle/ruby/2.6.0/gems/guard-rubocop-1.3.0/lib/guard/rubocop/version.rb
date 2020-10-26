# A workaround for declaring `class RuboCop`
# before `class RuboCop < Guard` in rubocop.rb
module GuardRuboCopVersion
  # http://semver.org/
  MAJOR = 1
  MINOR = 3
  PATCH = 0

  def self.to_s
    [MAJOR, MINOR, PATCH].join('.')
  end
end
