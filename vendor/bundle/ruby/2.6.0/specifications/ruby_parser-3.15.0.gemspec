# -*- encoding: utf-8 -*-
# stub: ruby_parser 3.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby_parser".freeze
  s.version = "3.15.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/seattlerb/ruby_parser/issues", "homepage_uri" => "https://github.com/seattlerb/ruby_parser" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Davis".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDPjCCAiagAwIBAgIBBDANBgkqhkiG9w0BAQsFADBFMRMwEQYDVQQDDApyeWFu\nZC1ydWJ5MRkwFwYKCZImiZPyLGQBGRYJemVuc3BpZGVyMRMwEQYKCZImiZPyLGQB\nGRYDY29tMB4XDTE5MTIxMzAwMDIwNFoXDTIwMTIxMjAwMDIwNFowRTETMBEGA1UE\nAwwKcnlhbmQtcnVieTEZMBcGCgmSJomT8ixkARkWCXplbnNwaWRlcjETMBEGCgmS\nJomT8ixkARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALda\nb9DCgK+627gPJkB6XfjZ1itoOQvpqH1EXScSaba9/S2VF22VYQbXU1xQXL/WzCkx\ntaCPaLmfYIaFcHHCSY4hYDJijRQkLxPeB3xbOfzfLoBDbjvx5JxgJxUjmGa7xhcT\noOvjtt5P8+GSK9zLzxQP0gVLS/D0FmoE44XuDr3iQkVS2ujU5zZL84mMNqNB1znh\nGiadM9GHRaDiaxuX0cIUBj19T01mVE2iymf9I6bEsiayK/n6QujtyCbTWsAS9Rqt\nqhtV7HJxNKuPj/JFH0D2cswvzznE/a5FOYO68g+YCuFi5L8wZuuM8zzdwjrWHqSV\ngBEfoTEGr7Zii72cx+sCAwEAAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAw\nHQYDVR0OBBYEFEfFe9md/r/tj/Wmwpy+MI8d9k/hMA0GCSqGSIb3DQEBCwUAA4IB\nAQCkkcHqAa6IKLYGl93rn78J3L+LnqyxaA059n4IGMHWN5bv9KBQnIjOrpLadtYZ\nvhWkunWDKdfVapBEq5+T4HzqnsEXC3aCv6JEKJY6Zw7iSzl0M8hozuzRr+w46wvT\nfV2yTN6QTVxqbMsJJyjosks4ZdQYov2zdvQpt1HsLi+Qmckmg8SPZsd+T8uiiBCf\nb+1ORSM5eEfBQenPXy83LZcoQz8i6zVB4aAfTGGdhxjoMGUEmSZ6xpkOzmnGa9QK\nm5x9IDiApM+vCELNwDXXGNFEnQBBK+wAe4Pek8o1V1TTOxL1kGPewVOitX1p3xoN\nh7iEjga8iM1LbZUfiISZ+WrB\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2020-09-01"
  s.description = "ruby_parser (RP) is a ruby parser written in pure ruby (utilizing\nracc--which does by default use a C extension). It outputs\ns-expressions which can be manipulated and converted back to ruby via\nthe ruby2ruby gem.\n\nAs an example:\n\n    def conditional1 arg1\n      return 1 if arg1 == 0\n      return 0\n    end\n\nbecomes:\n\n    s(:defn, :conditional1, s(:args, :arg1),\n      s(:if,\n        s(:call, s(:lvar, :arg1), :==, s(:lit, 0)),\n        s(:return, s(:lit, 1)),\n        nil),\n      s(:return, s(:lit, 0)))\n\nTested against 801,039 files from the latest of all rubygems (as of 2013-05):\n\n* 1.8 parser is at 99.9739% accuracy, 3.651 sigma\n* 1.9 parser is at 99.9940% accuracy, 4.013 sigma\n* 2.0 parser is at 99.9939% accuracy, 4.008 sigma".freeze
  s.email = ["ryand-ruby@zenspider.com".freeze]
  s.executables = ["ruby_parse".freeze, "ruby_parse_extract_error".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "debugging.md".freeze]
  s.files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "bin/ruby_parse".freeze, "bin/ruby_parse_extract_error".freeze, "debugging.md".freeze]
  s.homepage = "https://github.com/seattlerb/ruby_parser".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.1".freeze, "< 3.1".freeze])
  s.rubygems_version = "3.0.3".freeze
  s.summary = "ruby_parser (RP) is a ruby parser written in pure ruby (utilizing racc--which does by default use a C extension)".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sexp_processor>.freeze, ["~> 4.9"])
      s.add_development_dependency(%q<rake>.freeze, ["< 11"])
      s.add_development_dependency(%q<oedipus_lex>.freeze, ["~> 2.5"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_development_dependency(%q<racc>.freeze, ["~> 1.4.6"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.22"])
    else
      s.add_dependency(%q<sexp_processor>.freeze, ["~> 4.9"])
      s.add_dependency(%q<rake>.freeze, ["< 11"])
      s.add_dependency(%q<oedipus_lex>.freeze, ["~> 2.5"])
      s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_dependency(%q<racc>.freeze, ["~> 1.4.6"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.22"])
    end
  else
    s.add_dependency(%q<sexp_processor>.freeze, ["~> 4.9"])
    s.add_dependency(%q<rake>.freeze, ["< 11"])
    s.add_dependency(%q<oedipus_lex>.freeze, ["~> 2.5"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<racc>.freeze, ["~> 1.4.6"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.22"])
  end
end
