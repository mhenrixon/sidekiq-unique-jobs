= net-http-pipeline

* http://docs.seattlerb.org/net-http-pipeline
* http://github.com/drbrain/net-http-pipeline

== DESCRIPTION:

An HTTP/1.1 pipelining implementation atop Net::HTTP.  A pipelined connection
sends multiple requests to the HTTP server without waiting for the responses.
The server will respond in-order.

== FEATURES/PROBLEMS:

* Provides HTTP/1.1 pipelining

== SYNOPSIS:

  require 'net/http/pipeline'

  Net::HTTP.start 'localhost' do |http|
    req1 = Net::HTTP::Get.new '/'
    req2 = Net::HTTP::Get.new '/'
    req3 = Net::HTTP::Get.new '/'

    http.pipeline [req1, req2, req3] do |res|
      puts res.code
      puts res.body[0..60].inspect
      puts
    end
  end

== INSTALL:

  gem install net-http-pipeline

== LICENSE:

(The MIT License)

Copyright (c) 2010 Eric Hodel

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
