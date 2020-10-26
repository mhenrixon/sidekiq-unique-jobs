# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :travis

Hoe.spec 'net-http-persistent' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  self.readme_file      = 'README.rdoc'
  self.extra_rdoc_files += Dir['*.rdoc']

  license 'MIT'

  rdoc_locations <<
    'docs.seattlerb.org:/data/www/docs.seattlerb.org/net-http-persistent/'

  dependency 'minitest', '~> 5.2', :development
end

# vim: syntax=Ruby
