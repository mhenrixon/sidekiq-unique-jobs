require 'rubygems'
require 'minitest/autorun'
require 'net/http/persistent'
have_ssl =
  begin
    require 'openssl'
    require 'webrick'
    require 'webrick/ssl'
    true
  rescue LoadError
    false
  end

##
# This test is based on (and contains verbatim code from) the Net::HTTP tests
# in ruby

class TestNetHttpPersistentSSLReuse < Minitest::Test

  class NullWriter
    def <<(s) end
    def puts(*args) end
    def print(*args) end
    def printf(*args) end
  end

  def setup
    @name = OpenSSL::X509::Name.parse 'CN=localhost/DC=localdomain'

    @key = OpenSSL::PKey::RSA.new 1024

    @cert = OpenSSL::X509::Certificate.new
    @cert.version = 2
    @cert.serial = 0
    @cert.not_before = Time.now
    @cert.not_after = Time.now + 300
    @cert.public_key = @key.public_key
    @cert.subject = @name
    @cert.issuer = @name

    @cert.sign @key, OpenSSL::Digest::SHA1.new

    @host = 'localhost'
    @port = 10082

    config = {
      :BindAddress                => @host,
      :Port                       => @port,
      :Logger                     => WEBrick::Log.new(NullWriter.new),
      :AccessLog                  => [],
      :ShutDownSocketWithoutClose => true,
      :ServerType                 => Thread,
      :SSLEnable                  => true,
      :SSLCertificate             => @cert,
      :SSLPrivateKey              => @key,
      :SSLStartImmediately        => true,
    }

    @server = WEBrick::HTTPServer.new config

    @server.mount_proc '/' do |req, res|
      res.body = "ok"
    end

    @server.start

    begin
      TCPSocket.open(@host, @port).close
    rescue Errno::ECONNREFUSED
      sleep 0.2
      n_try_max -= 1
      raise 'cannot spawn server; give up' if n_try_max < 0
      retry
    end
  end

  def teardown
    if @server then
      @server.shutdown
      sleep 0.01 until @server.status == :Stop
    end
  end

  def test_ssl_connection_reuse
    store = OpenSSL::X509::Store.new
    store.add_cert @cert

    @http = Net::HTTP::Persistent::SSLReuse.new @host, @port
    @http.cert_store = store
    @http.ssl_version = :SSLv3 if @http.respond_to? :ssl_version=
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    @http.start
    @http.get '/'
    @http.finish

    @http.start
    @http.get '/'
    @http.finish

    @http.start
    @http.get '/'

    socket = @http.instance_variable_get :@socket
    ssl_socket = socket.io

    assert ssl_socket.session_reused?
  end

end if have_ssl

