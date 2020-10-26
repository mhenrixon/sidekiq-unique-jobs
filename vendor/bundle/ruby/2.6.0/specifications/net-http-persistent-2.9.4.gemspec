# -*- encoding: utf-8 -*-
# stub: net-http-persistent 2.9.4 ruby lib

Gem::Specification.new do |s|
  s.name = "net-http-persistent".freeze
  s.version = "2.9.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Hodel".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDeDCCAmCgAwIBAgIBATANBgkqhkiG9w0BAQUFADBBMRAwDgYDVQQDDAdkcmJy\nYWluMRgwFgYKCZImiZPyLGQBGRYIc2VnbWVudDcxEzARBgoJkiaJk/IsZAEZFgNu\nZXQwHhcNMTMwMjI4MDUyMjA4WhcNMTQwMjI4MDUyMjA4WjBBMRAwDgYDVQQDDAdk\ncmJyYWluMRgwFgYKCZImiZPyLGQBGRYIc2VnbWVudDcxEzARBgoJkiaJk/IsZAEZ\nFgNuZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCbbgLrGLGIDE76\nLV/cvxdEzCuYuS3oG9PrSZnuDweySUfdp/so0cDq+j8bqy6OzZSw07gdjwFMSd6J\nU5ddZCVywn5nnAQ+Ui7jMW54CYt5/H6f2US6U0hQOjJR6cpfiymgxGdfyTiVcvTm\nGj/okWrQl0NjYOYBpDi+9PPmaH2RmLJu0dB/NylsDnW5j6yN1BEI8MfJRR+HRKZY\nmUtgzBwF1V4KIZQ8EuL6I/nHVu07i6IkrpAgxpXUfdJQJi0oZAqXurAV3yTxkFwd\ng62YrrW26mDe+pZBzR6bpLE+PmXCzz7UxUq3AE0gPHbiMXie3EFE0oxnsU3lIduh\nsCANiQ8BAgMBAAGjezB5MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQW\nBBS5k4Z75VSpdM0AclG2UvzFA/VW5DAfBgNVHREEGDAWgRRkcmJyYWluQHNlZ21l\nbnQ3Lm5ldDAfBgNVHRIEGDAWgRRkcmJyYWluQHNlZ21lbnQ3Lm5ldDANBgkqhkiG\n9w0BAQUFAAOCAQEAOflo4Md5aJF//EetzXIGZ2EI5PzKWX/mMpp7cxFyDcVPtTv0\njs/6zWrWSbd60W9Kn4ch3nYiATFKhisgeYotDDz2/pb/x1ivJn4vEvs9kYKVvbF8\nV7MV/O5HDW8Q0pA1SljI6GzcOgejtUMxZCyyyDdbUpyAMdt9UpqTZkZ5z1sicgQk\n5o2XJ+OhceOIUVqVh1r6DNY5tLVaGJabtBmJAYFVznDcHiSFybGKBa5n25Egql1t\nKDyY1VIazVgoC8XvR4h/95/iScPiuglzA+DBG1hip1xScAtw05BrXyUNrc9CEMYU\nwgF94UVoHRp6ywo8I7NP3HcwFQDFNEZPNGXsng==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2014-02-10"
  s.description = "Manages persistent connections using Net::HTTP plus a speed fix for Ruby 1.8.\nIt's thread-safe too!\n\nUsing persistent HTTP connections can dramatically increase the speed of HTTP.\nCreating a new HTTP connection for every request involves an extra TCP\nround-trip and causes TCP congestion avoidance negotiation to start over.\n\nNet::HTTP supports persistent connections with some API methods but does not\nhandle reconnection gracefully.  Net::HTTP::Persistent supports reconnection\nand retry according to RFC 2616.".freeze
  s.email = ["drbrain@segment7.net".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = ["History.txt".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.homepage = "http://docs.seattlerb.org/net-http-persistent".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Manages persistent connections using Net::HTTP plus a speed fix for Ruby 1.8".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.2"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.7"])
    else
      s.add_dependency(%q<minitest>.freeze, ["~> 5.2"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.7"])
    end
  else
    s.add_dependency(%q<minitest>.freeze, ["~> 5.2"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.7"])
  end
end
