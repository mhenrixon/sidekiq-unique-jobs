# coding: utf-8

module Guard
  # A workaround for declaring `class Reek`
  # before `class Reek < Guard` in reek.rb
  module ReekVersion
    # http://semver.org/
    MAJOR = 1
    MINOR = 2
    PATCH = 0

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end
end
