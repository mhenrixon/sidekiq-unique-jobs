require 'rubygems'
require 'minitest/autorun'
require 'net/http/persistent'
require 'stringio'

HAVE_OPENSSL = defined?(OpenSSL::SSL)

module Net::HTTP::Persistent::TestConnect
  def self.included mod
    mod.send :alias_method, :orig_connect, :connect

    def mod.use_connect which
      self.send :remove_method, :connect
      self.send :alias_method, :connect, which
    end
  end

  def host_down_connect
    raise Errno::EHOSTDOWN
  end

  def test_connect
    unless use_ssl? then
      io = Object.new
      def io.setsockopt(*a) @setsockopts ||= []; @setsockopts << a end

      @socket = Net::BufferedIO.new io

      return
    end

    io = open '/dev/null'
    def io.setsockopt(*a) @setsockopts ||= []; @setsockopts << a end

    @ssl_context ||= OpenSSL::SSL::SSLContext.new

    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER unless
      @ssl_context.verify_mode

    s = OpenSSL::SSL::SSLSocket.new io, @ssl_context

    @socket = Net::BufferedIO.new s
  end

  def refused_connect
    raise Errno::ECONNREFUSED
  end
end

class Net::HTTP
  include Net::HTTP::Persistent::TestConnect
end

class Net::HTTP::Persistent::SSLReuse
  include Net::HTTP::Persistent::TestConnect
end

class TestNetHttpPersistent < Minitest::Test

  RUBY_1 = RUBY_VERSION < '2'

  def setup
    @http_class = if RUBY_1 and HAVE_OPENSSL then
                    Net::HTTP::Persistent::SSLReuse
                  else
                    Net::HTTP
                  end

    @http = Net::HTTP::Persistent.new

    @uri  = URI.parse 'http://example.com/path'

    ENV.delete 'http_proxy'
    ENV.delete 'HTTP_PROXY'
    ENV.delete 'http_proxy_user'
    ENV.delete 'HTTP_PROXY_USER'
    ENV.delete 'http_proxy_pass'
    ENV.delete 'HTTP_PROXY_PASS'
    ENV.delete 'no_proxy'
    ENV.delete 'NO_PROXY'

    Net::HTTP.use_connect :test_connect
    Net::HTTP::Persistent::SSLReuse.use_connect :test_connect
  end

  def teardown
    Thread.current.keys.each do |key|
      Thread.current[key] = nil
    end

    Net::HTTP.use_connect :orig_connect
    Net::HTTP::Persistent::SSLReuse.use_connect :orig_connect
  end

  class BasicConnection
    attr_accessor :started, :finished, :address, :port,
                  :read_timeout, :open_timeout
    attr_reader :req, :debug_output
    def initialize
      @started, @finished = 0, 0
      @address, @port = 'example.com', 80
    end
    def finish
      @finished += 1
      @socket = nil
    end
    def finished?
      @finished >= 1
    end
    def pipeline requests, &block
      requests.map { |r| r.path }
    end
    def reset?
      @started == @finished + 1
    end
    def set_debug_output io
      @debug_output = io
    end
    def start
      @started += 1
      io = Object.new
      def io.setsockopt(*a) @setsockopts ||= []; @setsockopts << a end
      @socket = Net::BufferedIO.new io
    end
    def started?
      @started >= 1
    end
  end

  def basic_connection
    raise "#{@uri} is not HTTP" unless @uri.scheme.downcase == 'http'

    c = BasicConnection.new
    conns[0]["#{@uri.host}:#{@uri.port}"] = c
    c
  end

  def connection
    c = basic_connection
    touts[c.object_id] = Time.now

    def c.request(req)
      @req = req
      r = Net::HTTPResponse.allocate
      r.instance_variable_set :@header, {}
      def r.http_version() '1.1' end
      def r.read_body() :read_body end
      yield r if block_given?
      r
    end

    c
  end

  def conns
    Thread.current[@http.generation_key] ||= Hash.new { |h,k| h[k] = {} }
  end

  def reqs
    Thread.current[@http.request_key] ||= Hash.new 0
  end

  def ssl_conns
    Thread.current[@http.ssl_generation_key] ||= Hash.new { |h,k| h[k] = {} }
  end

  def ssl_connection generation = 0
    raise "#{@uri} is not HTTPS" unless @uri.scheme.downcase == 'https'
    c = BasicConnection.new
    ssl_conns[generation]["#{@uri.host}:#{@uri.port}"] = c
    c
  end

  def touts
    Thread.current[@http.timeout_key] ||= Hash.new Net::HTTP::Persistent::EPOCH
  end

  def test_initialize
    assert_nil @http.proxy_uri

    assert_empty @http.no_proxy

    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    ssl_session_exists = OpenSSL::SSL.const_defined? :Session

    assert_equal ssl_session_exists, @http.reuse_ssl_sessions
  end

  def test_initialize_name
    http = Net::HTTP::Persistent.new 'name'
    assert_equal 'name', http.name
  end

  def test_initialize_no_ssl_session
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    skip "OpenSSL::SSL::Session does not exist on #{RUBY_PLATFORM}" unless
      OpenSSL::SSL.const_defined? :Session

    ssl_session = OpenSSL::SSL::Session

    OpenSSL::SSL.send :remove_const, :Session

    http = Net::HTTP::Persistent.new

    refute http.reuse_ssl_sessions
  ensure
    OpenSSL::SSL.const_set :Session, ssl_session if ssl_session
  end

  def test_initialize_proxy
    proxy_uri = URI.parse 'http://proxy.example'

    http = Net::HTTP::Persistent.new nil, proxy_uri

    assert_equal proxy_uri, http.proxy_uri
  end

  def test_ca_file_equals
    @http.ca_file = :ca_file

    assert_equal :ca_file, @http.ca_file
    assert_equal 1, @http.ssl_generation
  end

  def test_can_retry_eh_change_requests
    post = Net::HTTP::Post.new '/'

    refute @http.can_retry? post

    @http.retry_change_requests = true

    assert @http.can_retry? post
  end

  if RUBY_1 then
    def test_can_retry_eh_idempotent
      head = Net::HTTP::Head.new '/'

      assert @http.can_retry? head

      post = Net::HTTP::Post.new '/'

      refute @http.can_retry? post
    end
  else
    def test_can_retry_eh_idempotent
      head = Net::HTTP::Head.new '/'

      assert @http.can_retry? head
      refute @http.can_retry? head, true

      post = Net::HTTP::Post.new '/'

      refute @http.can_retry? post
    end
  end

  def test_cert_store_equals
    @http.cert_store = :cert_store

    assert_equal :cert_store, @http.cert_store
    assert_equal 1, @http.ssl_generation
  end

  def test_certificate_equals
    @http.certificate = :cert

    assert_equal :cert, @http.certificate
    assert_equal 1, @http.ssl_generation
  end

  def test_connection_for
    @http.open_timeout = 123
    @http.read_timeout = 321
    @http.idle_timeout = 42
    c = @http.connection_for @uri

    assert_kind_of @http_class, c

    assert c.started?
    refute c.proxy?

    assert_equal 123, c.open_timeout
    assert_equal 321, c.read_timeout
    assert_equal 42, c.keep_alive_timeout unless RUBY_1

    assert_includes conns[0].keys, 'example.com:80'
    assert_same c, conns[0]['example.com:80']
  end

  def test_connection_for_cached
    cached = basic_connection
    cached.start
    conns[0]['example.com:80'] = cached

    @http.read_timeout = 5

    c = @http.connection_for @uri

    assert c.started?

    assert_equal 5,       c.read_timeout

    assert_same cached, c
  end

  def test_connection_for_closed
    cached = basic_connection
    cached.start
    if Socket.const_defined? :TCP_NODELAY then
      io = Object.new
      def io.setsockopt(*a) raise IOError, 'closed stream' end
      cached.instance_variable_set :@socket, Net::BufferedIO.new(io)
    end
    conns['example.com:80'] = cached

    c = @http.connection_for @uri

    assert c.started?

    assert_includes conns.keys, 'example.com:80'
    assert_same c, conns[0]['example.com:80']

    socket = c.instance_variable_get :@socket

    refute_includes socket.io.instance_variables, :@setsockopt
    refute_includes socket.io.instance_variables, '@setsockopt'
  end

  def test_connection_for_debug_output
    io = StringIO.new
    @http.debug_output = io

    c = @http.connection_for @uri

    assert c.started?
    assert_equal io, c.instance_variable_get(:@debug_output)

    assert_includes conns[0].keys, 'example.com:80'
    assert_same c, conns[0]['example.com:80']
  end

  def test_connection_for_cached_expire_always
    cached = basic_connection
    cached.start
    conns[0]['example.com:80'] = cached
    reqs[cached.object_id] = 10
    touts[cached.object_id] = Time.now # last used right now

    @http.idle_timeout = 0

    c = @http.connection_for @uri

    assert c.started?

    assert_same cached, c

    assert_equal 0, reqs[cached.object_id],
                 'connection reset due to timeout'
  end

  def test_connection_for_cached_expire_never
    cached = basic_connection
    cached.start
    conns[0]['example.com:80'] = cached
    reqs[cached.object_id] = 10
    touts[cached.object_id] = Time.now # last used right now

    @http.idle_timeout = nil

    c = @http.connection_for @uri

    assert c.started?

    assert_same cached, c

    assert_equal 10, reqs[cached.object_id],
                 'connection reset despite no timeout'
  end

  def test_connection_for_cached_expired
    cached = basic_connection
    cached.start
    conns[0]['example.com:80'] = cached
    reqs[cached.object_id] = 10
    touts[cached.object_id] = Time.now - 3600

    c = @http.connection_for @uri

    assert c.started?

    assert_same cached, c
    assert_equal 0, reqs[cached.object_id],
                 'connection not reset due to timeout'
  end

  def test_connection_for_refused
    Net::HTTP.use_connect :refused_connect
    Net::HTTP::Persistent::SSLReuse.use_connect :refused_connect

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.connection_for @uri
    end

    assert_equal 'connection refused: example.com:80', e.message
  end

  def test_connection_for_finished_ssl
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'https://example.com/path'
    c = @http.connection_for uri

    assert c.started?
    assert c.use_ssl?

    @http.finish c

    refute c.started?

    c2 = @http.connection_for uri

    assert c2.started?
  end

  def test_connection_for_host_down
    cached = basic_connection
    def cached.start; raise Errno::EHOSTDOWN end
    def cached.started?; false end
    conns[0]['example.com:80'] = cached

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.connection_for @uri
    end

    assert_equal 'host down: example.com:80', e.message
  end

  def test_connection_for_http_class_with_fakeweb
    Object.send :const_set, :FakeWeb, nil
    c = @http.connection_for @uri
    assert_instance_of Net::HTTP, c
  ensure
    if Object.const_defined?(:FakeWeb) then
      Object.send :remove_const, :FakeWeb
    end
  end

  def test_connection_for_http_class_with_webmock
    Object.send :const_set, :WebMock, nil
    c = @http.connection_for @uri
    assert_instance_of Net::HTTP, c
  ensure
    if Object.const_defined?(:WebMock) then
      Object.send :remove_const, :WebMock
    end
  end

  def test_connection_for_http_class_with_artifice
    Object.send :const_set, :Artifice, nil
    c = @http.connection_for @uri
    assert_instance_of Net::HTTP, c
  ensure
    if Object.const_defined?(:Artifice) then
      Object.send :remove_const, :Artifice
    end
  end

  def test_connection_for_name
    http = Net::HTTP::Persistent.new 'name'
    uri = URI.parse 'http://example/'

    c = http.connection_for uri

    assert c.started?

    refute_includes conns.keys, 'example:80'
  end

  def test_connection_for_no_ssl_reuse
    @http.reuse_ssl_sessions = false
    @http.open_timeout = 123
    @http.read_timeout = 321
    c = @http.connection_for @uri

    assert_instance_of Net::HTTP, c
  end

  def test_connection_for_proxy
    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'

    http = Net::HTTP::Persistent.new nil, uri

    c = http.connection_for @uri

    assert c.started?
    assert c.proxy?

    assert_includes conns[1].keys,
                    'example.com:80:proxy.example:80:johndoe:muffins'
    assert_same c, conns[1]['example.com:80:proxy.example:80:johndoe:muffins']
  end

  def test_connection_for_proxy_unescaped
    uri = URI.parse 'http://proxy.example'
    uri.user = 'john%40doe'
    uri.password = 'muf%3Afins'
    uri.freeze

    http = Net::HTTP::Persistent.new nil, uri
    c = http.connection_for @uri

    assert_includes conns[1].keys,
                    'example.com:80:proxy.example:80:john@doe:muf:fins'
  end

  def test_connection_for_proxy_host_down
    Net::HTTP.use_connect :host_down_connect
    Net::HTTP::Persistent::SSLReuse.use_connect :host_down_connect

    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'

    http = Net::HTTP::Persistent.new nil, uri

    e = assert_raises Net::HTTP::Persistent::Error do
      http.connection_for @uri
    end

    assert_equal 'host down: proxy.example:80', e.message
  end

  def test_connection_for_proxy_refused
    Net::HTTP.use_connect :refused_connect
    Net::HTTP::Persistent::SSLReuse.use_connect :refused_connect

    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'

    http = Net::HTTP::Persistent.new nil, uri

    e = assert_raises Net::HTTP::Persistent::Error do
      http.connection_for @uri
    end

    assert_equal 'connection refused: proxy.example:80', e.message
  end

  def test_connection_for_no_proxy
    uri = URI.parse 'http://proxy.example'
    uri.user     = 'johndoe'
    uri.password = 'muffins'
    uri.query    = 'no_proxy=example.com'

    http = Net::HTTP::Persistent.new nil, uri

    c = http.connection_for @uri

    assert c.started?
    refute c.proxy?

    assert_includes conns[1].keys, 'example.com:80'
    assert_same c, conns[1]['example.com:80']
  end

  def test_connection_for_refused
    cached = basic_connection
    def cached.start; raise Errno::ECONNREFUSED end
    def cached.started?; false end
    conns[0]['example.com:80'] = cached

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.connection_for @uri
    end

    assert_match %r%connection refused%, e.message
  end

  def test_connection_for_ssl
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'https://example.com/path'
    c = @http.connection_for uri

    assert c.started?
    assert c.use_ssl?
  end

  def test_connection_for_ssl_cached
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @uri = URI.parse 'https://example.com/path'

    cached = ssl_connection 0

    c = @http.connection_for @uri

    assert_same cached, c
  end

  def test_connection_for_ssl_cached_reconnect
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @uri = URI.parse 'https://example.com/path'

    cached = ssl_connection

    @http.reconnect_ssl

    c = @http.connection_for @uri

    refute_same cached, c
  end

  def test_connection_for_ssl_case
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'HTTPS://example.com/path'
    c = @http.connection_for uri

    assert c.started?
    assert c.use_ssl?
  end

  def test_connection_for_timeout
    cached = basic_connection
    cached.start
    reqs[cached.object_id] = 10
    touts[cached.object_id] = Time.now - 6
    conns[0]['example.com:80'] = cached

    c = @http.connection_for @uri

    assert c.started?
    assert_equal 0, reqs[c.object_id]

    assert_same cached, c
  end

  def test_error_message
    c = basic_connection
    touts[c.object_id] = Time.now - 1
    reqs[c.object_id] = 5

    message = @http.error_message(c)
    assert_match %r%after 4 requests on #{c.object_id}%, message
    assert_match %r%, last used [\d.]+ seconds ago%, message
  end

  def test_escape
    assert_nil @http.escape nil

    assert_equal '+%3F', @http.escape(' ?')
  end

  def test_unescape
    assert_nil @http.unescape nil

    assert_equal ' ?', @http.unescape('+%3F')
  end

  def test_expired_eh
    c = basic_connection
    reqs[c.object_id] = 0
    touts[c.object_id] = Time.now - 11

    @http.idle_timeout = 0
    assert @http.expired? c

    @http.idle_timeout = 10
    assert @http.expired? c

    @http.idle_timeout = 11
    assert @http.expired? c

    @http.idle_timeout = 12
    refute @http.expired? c

    @http.idle_timeout = nil
    refute @http.expired? c
  end

  def test_expired_due_to_max_requests
    c = basic_connection
    reqs[c.object_id] = 0
    touts[c.object_id] = Time.now

    refute @http.expired? c

    reqs[c.object_id] = 10
    refute @http.expired? c

    @http.max_requests = 10
    assert @http.expired? c

    reqs[c.object_id] = 9
    refute @http.expired? c
  end

  def test_finish
    c = basic_connection
    reqs[c.object_id] = 5

    @http.finish c

    refute c.started?
    assert c.finished?
    assert_equal 0, reqs[c.object_id]
  end

  def test_finish_io_error
    c = basic_connection
    def c.finish; @finished += 1; raise IOError end
    reqs[c.object_id] = 5

    @http.finish c

    refute c.started?
    assert c.finished?
  end

  def test_http_version
    assert_nil @http.http_version @uri

    connection

    @http.request @uri

    assert_equal '1.1', @http.http_version(@uri)
  end

  def test_idempotent_eh
    assert @http.idempotent? Net::HTTP::Delete.new '/'
    assert @http.idempotent? Net::HTTP::Get.new '/'
    assert @http.idempotent? Net::HTTP::Head.new '/'
    assert @http.idempotent? Net::HTTP::Options.new '/'
    assert @http.idempotent? Net::HTTP::Put.new '/'
    assert @http.idempotent? Net::HTTP::Trace.new '/'

    refute @http.idempotent? Net::HTTP::Post.new '/'
  end

  def test_max_age
    assert_in_delta Time.now - 5, @http.max_age

    @http.idle_timeout = nil

    assert_in_delta Time.now + 1, @http.max_age
  end

  def test_normalize_uri
    assert_equal 'http://example',  @http.normalize_uri('example')
    assert_equal 'http://example',  @http.normalize_uri('http://example')
    assert_equal 'https://example', @http.normalize_uri('https://example')
  end

  def test_override_haeders
    assert_empty @http.override_headers

    @http.override_headers['User-Agent'] = 'MyCustomAgent'

    expected = { 'User-Agent' => 'MyCustomAgent' }

    assert_equal expected, @http.override_headers
  end

  def test_pipeline
    skip 'net-http-pipeline not installed' unless defined?(Net::HTTP::Pipeline)

    cached = basic_connection
    cached.start
    conns['example.com:80'] = cached

    requests = [
      Net::HTTP::Get.new((@uri + '1').request_uri),
      Net::HTTP::Get.new((@uri + '2').request_uri),
    ]

    responses = @http.pipeline @uri, requests

    assert_equal 2, responses.length
    assert_equal '/1', responses.first
    assert_equal '/2', responses.last
  end

  def test_private_key_equals
    @http.private_key = :private_key

    assert_equal :private_key, @http.private_key
    assert_equal 1, @http.ssl_generation
  end

  def test_proxy_equals_env
    ENV['http_proxy'] = 'proxy.example'

    @http.proxy = :ENV

    assert_equal URI.parse('http://proxy.example'), @http.proxy_uri

    assert_equal 1, @http.generation, 'generation'
    assert_equal 1, @http.ssl_generation, 'ssl_generation'
  end

  def test_proxy_equals_nil
    @http.proxy = nil

    assert_equal nil, @http.proxy_uri

    assert_equal 1, @http.generation, 'generation'
    assert_equal 1, @http.ssl_generation, 'ssl_generation'
  end

  def test_proxy_equals_uri
    proxy_uri = URI.parse 'http://proxy.example'

    @http.proxy = proxy_uri

    assert_equal proxy_uri, @http.proxy_uri
  end

  def test_proxy_from_env
    ENV['http_proxy']      = 'proxy.example'
    ENV['http_proxy_user'] = 'johndoe'
    ENV['http_proxy_pass'] = 'muffins'
    ENV['NO_PROXY']        = 'localhost,example.com'

    uri = @http.proxy_from_env

    expected = URI.parse 'http://proxy.example'
    expected.user     = 'johndoe'
    expected.password = 'muffins'
    expected.query    = 'no_proxy=localhost%2Cexample.com'

    assert_equal expected, uri
  end

  def test_proxy_from_env_lower
    ENV['http_proxy']      = 'proxy.example'
    ENV['http_proxy_user'] = 'johndoe'
    ENV['http_proxy_pass'] = 'muffins'
    ENV['no_proxy']        = 'localhost,example.com'

    uri = @http.proxy_from_env

    expected = URI.parse 'http://proxy.example'
    expected.user     = 'johndoe'
    expected.password = 'muffins'
    expected.query    = 'no_proxy=localhost%2Cexample.com'

    assert_equal expected, uri
  end

  def test_proxy_from_env_nil
    uri = @http.proxy_from_env

    assert_nil uri

    ENV['http_proxy'] = ''

    uri = @http.proxy_from_env

    assert_nil uri
  end

  def test_proxy_from_env_no_proxy_star
    uri = @http.proxy_from_env

    assert_nil uri

    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = '*'

    uri = @http.proxy_from_env

    assert_nil uri
  end

  def test_proxy_bypass
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost,example.com:80'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'localhost', 80
    assert @http.proxy_bypass? 'localhost', 443
    assert @http.proxy_bypass? 'LOCALHOST', 80
    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.com', 443
    assert @http.proxy_bypass? 'www.example.com', 80
    refute @http.proxy_bypass? 'www.example.com', 443
    assert @http.proxy_bypass? 'endingexample.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_proxy_bypass_space
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost, example.com'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_proxy_bypass_trailing
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost,example.com,'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_proxy_bypass_double_comma
    ENV['http_proxy'] = 'proxy.example'
    ENV['no_proxy'] = 'localhost,,example.com'

    @http.proxy = :ENV

    assert @http.proxy_bypass? 'example.com', 80
    refute @http.proxy_bypass? 'example.org', 80
  end

  def test_reconnect
    result = @http.reconnect

    assert_equal 1, result
  end

  def test_reconnect_ssl
    result = @http.reconnect_ssl

    assert_equal 1, result
  end

  def test_request
    @http.override_headers['user-agent'] = 'test ua'
    @http.headers['accept'] = 'text/*'
    c = connection

    res = @http.request @uri
    req = c.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path

    assert_equal 'test ua',    req['user-agent']
    assert_match %r%text/\*%,  req['accept']

    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']

    assert_in_delta Time.now, touts[c.object_id]

    assert_equal 1, reqs[c.object_id]
  end

  def test_request_ETIMEDOUT
    c = basic_connection
    def c.request(*a) raise Errno::ETIMEDOUT, "timed out" end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request @uri
    end

    assert_equal 0, reqs[c.object_id]
    assert_match %r%too many connection resets%, e.message
  end

  def test_request_bad_response
    c = basic_connection
    def c.request(*a) raise Net::HTTPBadResponse end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request @uri
    end

    assert_equal 0, reqs[c.object_id]
    assert_match %r%too many bad responses%, e.message
  end

  if RUBY_1 then
    def test_request_bad_response_retry
      c = basic_connection
      def c.request(*a)
        if defined? @called then
          r = Net::HTTPResponse.allocate
          r.instance_variable_set :@header, {}
          def r.http_version() '1.1' end
          r
        else
          @called = true
          raise Net::HTTPBadResponse
        end
      end

      @http.request @uri

      assert c.finished?
    end
  else
    def test_request_bad_response_retry
      c = basic_connection
      def c.request(*a)
        raise Net::HTTPBadResponse
      end

      assert_raises Net::HTTP::Persistent::Error do
        @http.request @uri
      end

      assert c.finished?
    end
  end

  def test_request_bad_response_unsafe
    c = basic_connection
    def c.request(*a)
      if instance_variable_defined? :@request then
        raise 'POST must not be retried'
      else
        @request = true
        raise Net::HTTPBadResponse
      end
    end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request @uri, Net::HTTP::Post.new(@uri.path)
    end

    assert_equal 0, reqs[c.object_id]
    assert_match %r%too many bad responses%, e.message
  end

  def test_request_block
    @http.headers['user-agent'] = 'test ua'
    c = connection
    body = nil

    res = @http.request @uri do |r|
      body = r.read_body
    end

    req = c.req

    assert_kind_of Net::HTTPResponse, res
    refute_nil body

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']
    assert_match %r%test ua%,  req['user-agent']

    assert_equal 1, reqs[c.object_id]
  end

  def test_request_close_1_0
    c = connection

    class << c
      remove_method :request
    end

    def c.request req
      @req = req
      r = Net::HTTPResponse.allocate
      r.instance_variable_set :@header, {}
      def r.http_version() '1.0' end
      def r.read_body() :read_body end
      yield r if block_given?
      r
    end

    request = Net::HTTP::Get.new @uri.request_uri

    res = @http.request @uri, request
    req = c.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']

    assert c.finished?
  end

  def test_request_connection_close_request
    c = connection

    request = Net::HTTP::Get.new @uri.request_uri
    request['connection'] = 'close'

    res = @http.request @uri, request
    req = c.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'close',      req['connection']
    assert_equal nil,          req['keep-alive']

    assert c.finished?
  end

  def test_request_connection_close_response
    c = connection

    class << c
      remove_method :request
    end

    def c.request req
      @req = req
      r = Net::HTTPResponse.allocate
      r.instance_variable_set :@header, {}
      r['connection'] = 'close'
      def r.http_version() '1.1' end
      def r.read_body() :read_body end
      yield r if block_given?
      r
    end

    request = Net::HTTP::Get.new @uri.request_uri

    res = @http.request @uri, request
    req = c.req

    assert_kind_of Net::HTTPResponse, res

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path',      req.path
    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']

    assert c.finished?
  end

  def test_request_exception
    c = basic_connection
    def c.request(*a) raise Exception, "very bad things happened" end

    assert_raises Exception do
      @http.request @uri
    end

    assert_equal 0, reqs[c.object_id]
    assert c.finished?
  end

  def test_request_invalid
    c = basic_connection
    def c.request(*a) raise Errno::EINVAL, "write" end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request @uri
    end

    assert_equal 0, reqs[c.object_id]
    assert_match %r%too many connection resets%, e.message
  end

  def test_request_invalid_retry
    c = basic_connection
    touts[c.object_id] = Time.now

    def c.request(*a)
      if defined? @called then
        r = Net::HTTPResponse.allocate
        r.instance_variable_set :@header, {}
        def r.http_version() '1.1' end
        r
      else
        @called = true
        raise Errno::EINVAL, "write"
      end
    end

    @http.request @uri

    assert c.reset?
    assert c.finished?
  end

  def test_request_post
    c = connection

    post = Net::HTTP::Post.new @uri.path

    @http.request @uri, post
    req = c.req

    assert_same post, req
  end

  def test_request_reset
    c = basic_connection
    def c.request(*a) raise Errno::ECONNRESET end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request @uri
    end

    assert_equal 0, reqs[c.object_id]
    assert_match %r%too many connection resets%, e.message
  end

  if RUBY_1 then
    def test_request_reset_retry
      c = basic_connection
      touts[c.object_id] = Time.now
      def c.request(*a)
        if defined? @called then
          r = Net::HTTPResponse.allocate
          r.instance_variable_set :@header, {}
          def r.http_version() '1.1' end
          r
        else
          @called = true
          raise Errno::ECONNRESET
        end
      end

      @http.request @uri

      assert c.reset?
      assert c.finished?
    end
  else
    def test_request_reset_retry
      c = basic_connection
      touts[c.object_id] = Time.now

      def c.request(*a)
        raise Errno::ECONNRESET
      end

      assert_raises Net::HTTP::Persistent::Error do
        @http.request @uri
      end

      refute c.reset?
      assert c.finished?
    end
  end

  def test_request_reset_unsafe
    c = basic_connection
    def c.request(*a)
      if instance_variable_defined? :@request then
        raise 'POST must not be retried'
      else
        @request = true
        raise Errno::ECONNRESET
      end
    end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request @uri, Net::HTTP::Post.new(@uri.path)
    end

    assert_equal 0, reqs[c.object_id]
    assert_match %r%too many connection resets%, e.message
  end

  def test_request_ssl_error
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri = URI.parse 'https://example.com/path'
    c = @http.connection_for uri
    def c.request(*)
      raise OpenSSL::SSL::SSLError, "SSL3_WRITE_PENDING:bad write retry"
    end

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request uri
    end
    assert_match %r%bad write retry%, e.message
  end

  def test_request_setup
    @http.override_headers['user-agent'] = 'test ua'
    @http.headers['accept'] = 'text/*'

    input = Net::HTTP::Post.new '/path'

    req = @http.request_setup input

    assert_same input,         req
    assert_equal '/path',      req.path

    assert_equal 'test ua',    req['user-agent']
    assert_match %r%text/\*%,  req['accept']

    assert_equal 'keep-alive', req['connection']
    assert_equal '30',         req['keep-alive']
  end

  def test_request_setup_uri
    uri = @uri + '?a=b'

    req = @http.request_setup uri

    assert_kind_of Net::HTTP::Get, req
    assert_equal '/path?a=b',  req.path
  end

  def test_request_failed
    c = basic_connection
    reqs[c.object_id] = 1
    touts[c.object_id] = Time.now

    original = nil

    begin
      raise 'original'
    rescue => original
    end

    req = Net::HTTP::Get.new '/'
      
    e = assert_raises Net::HTTP::Persistent::Error do
      @http.request_failed original, req, c
    end

    assert_match "too many connection resets (due to original - RuntimeError)",
                 e.message

    assert_equal original.backtrace, e.backtrace
  end

  def test_reset
    c = basic_connection
    c.start
    touts[c.object_id] = Time.now
    reqs[c.object_id]  = 5

    @http.reset c

    assert c.started?
    assert c.finished?
    assert c.reset?
    assert_equal 0, reqs[c.object_id]
    assert_equal Net::HTTP::Persistent::EPOCH, touts[c.object_id]
  end

  def test_reset_host_down
    c = basic_connection
    touts[c.object_id] = Time.now
    def c.start; raise Errno::EHOSTDOWN end
    reqs[c.object_id] = 5

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.reset c
    end

    assert_match %r%host down%, e.message
    assert_match __FILE__, e.backtrace.first
  end

  def test_reset_io_error
    c = basic_connection
    touts[c.object_id] = Time.now
    reqs[c.object_id] = 5

    @http.reset c

    assert c.started?
    assert c.finished?
  end

  def test_reset_refused
    c = basic_connection
    touts[c.object_id] = Time.now
    def c.start; raise Errno::ECONNREFUSED end
    reqs[c.object_id] = 5

    e = assert_raises Net::HTTP::Persistent::Error do
      @http.reset c
    end

    assert_match %r%connection refused%, e.message
    assert_match __FILE__, e.backtrace.first
  end

  def test_retry_change_requests_equals
    get  = Net::HTTP::Get.new('/')
    post = Net::HTTP::Post.new('/')

    refute @http.retry_change_requests

    if RUBY_1 then
      assert @http.can_retry?(get)
    else
      assert @http.can_retry?(get)
    end
    refute @http.can_retry?(get, true)
    refute @http.can_retry?(post)

    @http.retry_change_requests = true

    assert @http.retry_change_requests

    if RUBY_1 then
      assert @http.can_retry?(get)
    else
      assert @http.can_retry?(get)
      refute @http.can_retry?(get, true)
    end

    assert @http.can_retry?(post)
  end

  def test_shutdown
    ssl_conns
    c = connection
    rs = reqs
    ts = touts

    orig = @http
    @http = Net::HTTP::Persistent.new 'name'
    c2 = connection

    orig.shutdown

    @http = orig

    assert c.finished?, 'last-generation connection must be finished'
    refute c2.finished?, 'present generation connection must not be finished'

    refute_same rs, reqs
    refute_same ts, touts

    assert_empty conns
    assert_empty ssl_conns

    assert_empty reqs
    assert_empty touts
  end

  def test_shutdown_in_all_threads
    conns
    ssl_conns

    t = Thread.new do
      c = connection
      ssl_conns
      conns
      reqs

      Thread.stop

      c
    end

    Thread.pass until t.status == 'sleep'

    c = connection

    assert_nil @http.shutdown_in_all_threads

    assert c.finished?, 'connection in same thread must be finished'

    assert_empty Thread.current[@http.generation_key]

    assert_nil Thread.current[@http.request_key]

    t.run
    assert t.value.finished?, 'connection in other thread must be finished'

    assert_empty t[@http.generation_key]

    assert_nil t[@http.request_key]
  end

  def test_shutdown_no_connections
    @http.shutdown

    assert_nil Thread.current[@http.generation_key]
    assert_nil Thread.current[@http.ssl_generation_key]

    assert_nil Thread.current[@http.request_key]
    assert_nil Thread.current[@http.timeout_key]
  end

  def test_shutdown_not_started
    ssl_conns

    c = basic_connection
    def c.finish() raise IOError end

    conns[0]["#{@uri.host}:#{@uri.port}"] = c

    @http.shutdown

    assert_empty Thread.current[@http.generation_key]
    assert_empty Thread.current[@http.ssl_generation_key]

    assert_nil Thread.current[@http.request_key]
    assert_nil Thread.current[@http.timeout_key]
  end

  def test_shutdown_ssl
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @uri = URI 'https://example'

    @http.connection_for @uri

    @http.shutdown

    assert_empty ssl_conns
  end

  def test_shutdown_thread
    t = Thread.new do
      c = connection
      conns
      ssl_conns

      reqs

      Thread.stop

      c
    end

    Thread.pass until t.status == 'sleep'

    c = connection

    @http.shutdown t

    refute c.finished?

    t.run
    assert t.value.finished?
    assert_empty t[@http.generation_key]
    assert_empty t[@http.ssl_generation_key]
    assert_nil t[@http.request_key]
    assert_nil t[@http.timeout_key]
  end

  def test_ssl
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.verify_callback = :callback
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, c.verify_mode
    assert_kind_of OpenSSL::X509::Store,    c.cert_store
    assert_nil c.verify_callback
  end

  def test_ssl_ca_file
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.ca_file = 'ca_file'
    @http.verify_callback = :callback
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_PEER, c.verify_mode
    assert_equal :callback, c.verify_callback
  end

  def test_ssl_cert_store
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    store = OpenSSL::X509::Store.new
    @http.cert_store = store

    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal store, c.cert_store
  end

  def test_ssl_cert_store_default
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert c.cert_store
  end

  def test_ssl_certificate
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.certificate = :cert
    @http.private_key = :key
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal :cert, c.cert
    assert_equal :key,  c.key
  end

  def test_ssl_verify_mode
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    c = Net::HTTP.new 'localhost', 80

    @http.ssl c

    assert c.use_ssl?
    assert_equal OpenSSL::SSL::VERIFY_NONE, c.verify_mode
  end

  def test_ssl_warning
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    begin
      orig_verify_peer = OpenSSL::SSL::VERIFY_PEER
      OpenSSL::SSL.send :remove_const, :VERIFY_PEER
      OpenSSL::SSL.send :const_set, :VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE

      c = Net::HTTP.new 'localhost', 80

      out, err = capture_io do
        @http.ssl c
      end

      assert_empty out

      assert_match %r%localhost:80%, err
      assert_match %r%I_KNOW_THAT_OPENSSL%, err

      Object.send :const_set, :I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG, nil

      assert_silent do
        @http.ssl c
      end
    ensure
      OpenSSL::SSL.send :remove_const, :VERIFY_PEER
      OpenSSL::SSL.send :const_set, :VERIFY_PEER, orig_verify_peer
      if Object.const_defined?(:I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG) then
        Object.send :remove_const, :I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG
      end
    end
  end

  def test_ssl_cleanup
    skip 'OpenSSL is missing' unless HAVE_OPENSSL

    uri1 = URI.parse 'https://one.example'

    c1 = @http.connection_for uri1

    touts[c1.object_id] = Time.now
    reqs[c1.object_id] = 5

    @http.reconnect_ssl

    @http.ssl_cleanup @http.ssl_generation

    assert_empty ssl_conns
    assert_empty touts
    assert_empty reqs # sanity check, performed by #finish
  end

  def test_ssl_version_equals
    @http.ssl_version = :ssl_version

    assert_equal :ssl_version, @http.ssl_version
    assert_equal 1, @http.ssl_generation
  end unless RUBY_1

  def test_start
    c = basic_connection

    @http.socket_options << [Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1]
    @http.debug_output = $stderr
    @http.open_timeout = 6

    @http.start c

    assert_equal $stderr, c.debug_output
    assert_equal 6,       c.open_timeout

    socket = c.instance_variable_get :@socket

    expected = []
    expected << [Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1] if
      Socket.const_defined? :TCP_NODELAY
    expected << [Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1]

    assert_equal expected, socket.io.instance_variable_get(:@setsockopts)
  end

  def test_verify_callback_equals
    @http.verify_callback = :verify_callback

    assert_equal :verify_callback, @http.verify_callback
    assert_equal 1, @http.ssl_generation
  end

  def test_verify_mode_equals
    @http.verify_mode = :verify_mode

    assert_equal :verify_mode, @http.verify_mode
    assert_equal 1, @http.ssl_generation
  end

end

