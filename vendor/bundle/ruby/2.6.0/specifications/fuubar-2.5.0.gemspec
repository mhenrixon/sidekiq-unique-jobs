# -*- encoding: utf-8 -*-
# stub: fuubar 2.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fuubar".freeze
  s.version = "2.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/thekompanee/fuubar/issues", "changelog_uri" => "https://github.com/thekompanee/fuubar/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/thekompanee/fuubar/tree/releases/v2.4.0", "homepage_uri" => "https://github.com/thekompanee/fuubar", "source_code_uri" => "https://github.com/thekompanee/fuubar", "wiki_uri" => "https://github.com/thekompanee/fuubar/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nicholas Evans".freeze, "Jeff Kreeftmeijer".freeze, "jfelchner".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEdjCCAt6gAwIBAgIBATANBgkqhkiG9w0BAQsFADAyMTAwLgYDVQQDDCdhY2Nv\ndW50c19ydWJ5Z2Vtcy9EQz10aGVrb21wYW5lZS9EQz1jb20wHhcNMTkwOTIwMDY1\nNjU5WhcNMjAwOTE5MDY1NjU5WjAyMTAwLgYDVQQDDCdhY2NvdW50c19ydWJ5Z2Vt\ncy9EQz10aGVrb21wYW5lZS9EQz1jb20wggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAw\nggGKAoIBgQD0Z84PxtE0iiWCMTQbnit6D4w55GGBQZnhpWUCJwC0SpQ/jnT0Fsma\ng8oAIdDclLvLC9jzqSAmkOujlpkJMb5NabgkhKFwHi6cVW/gz/cVnISAv8LQTIM5\nc1wyhwX/YhVFaNYNzMizB//kZOeXnv6x0tqV9NY7urHcT6mCwyLeNJIgf44i1Ut+\nmKtXxEyXNbfWQLVY95bVoVg3GOCkycerZN4Oh3zSJM1s+cZRBFlg7GR1AE3Xqs6k\nRhE7yp8ufeghC3bbxgnQrkk8W8Fkkl0/+2JAENpdE4OUepC6dFzDlLZ3UvSk7VHf\nNBRKSuO15kpPo2G55N0HLy8abUzbu5cqjhSbIk9hzD6AmdGCT4DqlsdHI5gOrGP0\nBO6VxGpRuRETKoZ4epPCsXC2XAwk3TJXkuuqYkgdcv8ZR4rPW2CiPvRqgG1YVwWj\nSrIy5Dt/dlMvxdIMiTj6ytAQP1kfdKPFWrJTIA2tspl/eNB+LiYsVdj8d0UU/KTY\ny7jqKMpOE1UCAwEAAaOBljCBkzAJBgNVHRMEAjAAMAsGA1UdDwQEAwIEsDAdBgNV\nHQ4EFgQU7+XQuN042fZGvzLhYbIwDfsxZV8wLAYDVR0RBCUwI4EhYWNjb3VudHMr\ncnVieWdlbXNAdGhla29tcGFuZWUuY29tMCwGA1UdEgQlMCOBIWFjY291bnRzK3J1\nYnlnZW1zQHRoZWtvbXBhbmVlLmNvbTANBgkqhkiG9w0BAQsFAAOCAYEACxEqDu9T\nqOrMNmrJSFUkVE/aAMJtbDhgpMoIq1e7drO5fM8mk161nfSpgf4JKIQqrK/7jCNe\nLL+OoqoKmnwWK0/M5I2exJqgdHS8AOZvTLrktXuv9UqTcR+Ryi/DenjhoFCVpMeQ\nR11SWmqLO/UAGtlKneO/rBzMax42NUNuRpVQsj2ey31mvtYw6dD1k0+vgAc5Boh8\n3QcVCsB8CYpC062u95ZnnTbs+++aKIj8HHgntJjhNZaCpJ5n+KmuqQrZEpYIn23x\nLQJp2syl3zPKRuR9SowlWW91gYxRv1iOv4Skn0ct2QOOY4nfczkAXZ++QQXdpBY8\nbhD2gZ4C5v23/Xg0mBvEdTtsXr7EPFF4ki7HJPHjcw2qi+VlXAUDvjpEOV3fJfdr\nueUkus2RBlHNjmQ1bzVommjkFSE0E4L0u8lrU7axdH6XsGt2VOx+m4qyPeU/seN1\nUTOujiMrrUIxVx+OYc1H9cGSvTGEualhzuCTUG17pW5mrck5LrVc/vq2\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2019-10-28"
  s.description = "the instafailing RSpec progress bar formatter".freeze
  s.email = ["jeff@kreeftmeijer.nl".freeze, "accounts+git@thekompanee.com".freeze]
  s.homepage = "https://github.com/thekompanee/fuubar".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "the instafailing RSpec progress bar formatter".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec-core>.freeze, ["~> 3.0"])
      s.add_runtime_dependency(%q<ruby-progressbar>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
    else
      s.add_dependency(%q<rspec-core>.freeze, ["~> 3.0"])
      s.add_dependency(%q<ruby-progressbar>.freeze, ["~> 1.4"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    end
  else
    s.add_dependency(%q<rspec-core>.freeze, ["~> 3.0"])
    s.add_dependency(%q<ruby-progressbar>.freeze, ["~> 1.4"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
  end
end
