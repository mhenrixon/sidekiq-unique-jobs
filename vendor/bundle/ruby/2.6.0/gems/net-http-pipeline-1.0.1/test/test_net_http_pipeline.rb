require 'minitest/autorun'
require 'net/http/pipeline'
require 'stringio'

class TestNetHttpPipeline < MiniTest::Unit::TestCase

  include Net::HTTP::Pipeline

  def setup
    @curr_http_version = '1.1'
    @started = true

    @get1 = Net::HTTP::Get.new '/'
    @get2 = Net::HTTP::Get.new '/'
    @get3 = Net::HTTP::Get.new '/'
    @post = Net::HTTP::Post.new '/'

    remove_start

    def start
    end
  end

  def remove_start
    class << self
      alias_method :old_start, :start if method_defined? :start
    end
  end

  ##
  # Net::BufferedIO stub

  class Buffer
    attr_accessor :read_io, :write_io
    def initialize exception = nil, immediate = false
      @readline = immediate
      @exception = exception

      @read_io = StringIO.new
      @write_io = StringIO.new
      @closed = false
    end

    def close
      @closed = true
    end

    def closed?
      @closed
    end

    def finish
      @write_io.rewind
    end

    def read bytes, dest = '', ignored = nil
      @read_io.read bytes, dest

      dest
    end

    def readline
      raise @exception if @exception and @readline
      @readline = true
      @read_io.readline.chomp "\r\n"
    end

    def readuntil terminator, ignored
      @read_io.gets terminator
    end

    def start
      @read_io.rewind
    end

    def write data
      @write_io.write data
    end
  end

  attr_writer :started

  def D(*) end

  def begin_transport req
  end

  def edit_path path
    path
  end

  def finish
    @socket.close
  end

  def http_get
    get = []
    get << 'GET / HTTP/1.1'
    get << 'Accept: */*'
    get << 'User-Agent: Ruby' if RUBY_VERSION > '1.9'
    get.push nil, nil

    get.join "\r\n"
  end

  def http_post
    get = []
    get << 'POST / HTTP/1.1'
    get << 'Accept: */*'
    get << 'User-Agent: Ruby' if RUBY_VERSION > '1.9'
    get.push nil, nil

    get.join "\r\n"
  end

  def http_response body, *extra_header
    http_response = []
    http_response << 'HTTP/1.1 200 OK'
    http_response << "Content-Length: #{body.bytesize}"
    http_response.push(*extra_header)
    http_response.push nil, nil # Array chomps on #join

    http_response.join("\r\n") << body
  end

  def http_bad_response
    http_response = []
    http_response << 'HTP/1.1 200 OK'
    http_response << 'Content-Length: 0'
    http_response.push nil, nil # Array chomps on #join

    http_response.join("\r\n")
  end

  def request req
    req.exec @socket, @curr_http_version, edit_path(req.path)

    res = Net::HTTPResponse.read_new @socket

    res.reading_body @socket, req.response_body_permitted? do
      yield res if block_given?
    end

    @curr_http_version = res.http_version

    @socket.close unless pipeline_keep_alive? res

    res
  end

  def response
    r = Net::HTTPResponse.allocate
    def r.http_version() Net::HTTP::HTTPVersion end
    def r.read_body() true end

    r.instance_variable_set :@header, {}
    def r.header() @header end
    r
  end

  def started?() @started end

  # tests start

  def test_idempotent_eh
    http = Net::HTTP.new 'localhost'

    assert http.idempotent? Net::HTTP::Delete.new '/'
    assert http.idempotent? Net::HTTP::Get.new '/'
    assert http.idempotent? Net::HTTP::Head.new '/'
    assert http.idempotent? Net::HTTP::Options.new '/'
    assert http.idempotent? Net::HTTP::Put.new '/'
    assert http.idempotent? Net::HTTP::Trace.new '/'

    refute http.idempotent? Net::HTTP::Post.new '/'
  end

  def test_pipeline
    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!')
    @socket.read_io.write http_response('Worked 2!')
    @socket.start

    requests = [@get1, @get2]

    responses = pipeline requests

    @socket.finish

    expected = http_get * 2

    assert_equal expected, @socket.write_io.read
    refute @socket.closed?

    assert_equal 'Worked 1!', responses.first.body
    assert_equal 'Worked 2!', responses.last.body

    assert_empty requests
  end

  def test_pipeline_block
    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!')
    @socket.read_io.write http_response('Worked 2!')
    @socket.start

    requests = [@get1, @get2]
    responses = []

    pipeline requests do |response| responses << response end

    @socket.finish

    assert_equal 'Worked 1!', responses.first.body
    assert_equal 'Worked 2!', responses.last.body
  end

  def test_pipeline_http_1_0
    @curr_http_version = '1.0'

    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!', 'Connection: close')
    @socket.start

    e = assert_raises Net::HTTP::Pipeline::VersionError do
      pipeline [@get1, @get2]
    end

    assert_equal [@get1, @get2], e.requests
    assert_empty e.responses
  end

  def test_pipeline_non_idempotent
    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!')
    @socket.read_io.write http_response('Worked 2!')
    @socket.read_io.write http_response('Worked 3!')
    @socket.read_io.write http_response('Worked 4!')
    @socket.start

    responses = pipeline [@get1, @get2, @post, @get3]

    @socket.finish

    expected = ''
    expected << http_get * 2
    expected << http_post
    expected << http_get

    assert_equal expected, @socket.write_io.read
    refute @socket.closed?

    assert_equal 'Worked 1!', responses.shift.body
    assert_equal 'Worked 2!', responses.shift.body
    assert_equal 'Worked 3!', responses.shift.body
    assert_equal 'Worked 4!', responses.shift.body

    assert responses.empty?
  end

  def test_pipeline_not_started
    @started = false

    e = assert_raises Net::HTTP::Pipeline::Error do
      pipeline []
    end

    assert_equal 'Net::HTTP not started', e.message
  end

  def test_pipeline_retry
    self.pipelining = true
    @error_socket = Buffer.new Errno::ECONNRESET
    @error_socket.read_io.write http_response('Worked 1!')
    @error_socket.start

    @good_socket = Buffer.new
    @good_socket.read_io.write http_response('Worked 2!')
    @good_socket.read_io.write http_response('Worked 3!')
    @good_socket.start

    @socket = @error_socket

    remove_start

    def start
      @socket = @good_socket
    end

    requests = [@get1, @get2, @get3]

    responses = pipeline requests

    @error_socket.finish
    @good_socket.finish

    assert_equal http_get * 3, @error_socket.write_io.read
    assert @error_socket.closed?

    assert_equal http_get * 2, @good_socket.write_io.read
    refute @good_socket.closed?

    assert_equal 'Worked 1!', responses.shift.body
    assert_equal 'Worked 2!', responses.shift.body
    assert_equal 'Worked 3!', responses.shift.body
    assert_empty responses

    assert_empty requests
  end

  def test_pipeline_retry_fail_post
    self.pipelining = true

    @socket = Buffer.new Errno::ECONNRESET, true
    @socket.start

    requests = [@post]

    e = assert_raises Net::HTTP::Pipeline::ResponseError do
      pipeline requests
    end

    @socket.finish

    assert_equal http_post, @socket.write_io.read

    assert_empty e.responses

    assert_equal [@post], e.requests
  end

  def test_pipeline_retry_fail_different
    self.pipelining = true
    @error_socket = Buffer.new Errno::ECONNRESET
    @error_socket.read_io.write http_response('Worked 1!')
    @error_socket.start

    @error_socket2 = Buffer.new Errno::ECONNRESET
    @error_socket2.read_io.write http_response('Worked 2!')
    @error_socket2.start

    @good_socket = Buffer.new
    @good_socket.read_io.write http_response('Worked 3!')
    @good_socket.start

    @socket = @error_socket

    @sockets = [@error_socket2, @good_socket]

    remove_start

    def start
      @socket = @sockets.shift
    end

    requests = [@get1, @get2, @get3]

    responses = pipeline requests

    @error_socket.finish
    @error_socket2.finish
    @good_socket.finish

    assert_equal http_get * 3, @error_socket.write_io.read
    assert @error_socket.closed?

    assert_equal http_get * 2, @error_socket2.write_io.read
    assert @error_socket2.closed?

    assert_equal http_get, @good_socket.write_io.read
    refute @good_socket.closed?

    assert_equal 'Worked 1!', responses.shift.body
    assert_equal 'Worked 2!', responses.shift.body
    assert_equal 'Worked 3!', responses.shift.body
    assert_empty responses

    assert_empty requests
  end

  def test_pipeline_retry_fail_same
    self.pipelining = true

    @error_socket = Buffer.new Errno::ECONNRESET
    @error_socket.read_io.write http_response('Worked 1!')
    @error_socket.start

    @error_socket2 = Buffer.new Errno::ECONNRESET, true
    @error_socket2.start

    @socket = @error_socket

    remove_start

    def start
      @socket = @error_socket2
    end

    requests = [@get1, @get2, @get3]

    e = assert_raises Net::HTTP::Pipeline::ResponseError do
      pipeline requests
    end

    @error_socket.finish
    @error_socket2.finish

    assert_equal http_get * 3, @error_socket.write_io.read
    assert @error_socket.closed?

    assert_equal http_get * 2, @error_socket2.write_io.read
    assert @error_socket2.closed?

    responses = e.responses
    assert_equal 'Worked 1!', responses.shift.body
    assert_empty responses

    assert_equal [@get2, @get3], e.requests
  end

  # end #pipeline tests

  def test_pipeline_check
    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!')
    @socket.start

    requests = [@get1, @get2]
    responses = []

    pipeline_check requests, responses

    assert_equal [@get2], requests
    assert_equal 1, responses.length
    assert_equal 'Worked 1!', responses.first.body
    assert pipelining
  end

  def test_pipeline_check_again
    self.pipelining = false

    @socket = Buffer.new
    @socket.start

    e = assert_raises Net::HTTP::Pipeline::PipelineError do
      pipeline_check [@get1, @get2], []
    end

    assert_equal [@get1, @get2], e.requests
    assert_empty e.responses
    refute pipelining
  end

  def test_pipeline_check_bad_response
    @socket = Buffer.new
    @socket.read_io.write http_bad_response
    @socket.start

    @socket2 = Buffer.new
    @socket2.read_io.write http_response('Worked 1!')
    @socket2.start

    remove_start

    def start
      @socket = @socket2
    end

    requests = [@get1, @get2]
    responses = []

    pipeline_check requests, responses

    assert_equal [@get2], requests
    assert_equal 1, responses.length
    assert_equal 'Worked 1!', responses.first.body
    assert pipelining
  end

  def test_pipeline_check_http_1_0
    @socket = Buffer.new
    @socket.read_io.write <<-HTTP_1_0
HTTP/1.0 200 OK\r
Content-Length: 9\r
\r
Worked 1!
    HTTP_1_0
    @socket.start

    e = assert_raises Net::HTTP::Pipeline::VersionError do
      pipeline_check [@get1, @get2], []
    end

    assert_equal [@get2], e.requests
    assert_equal 1, e.responses.length
    assert_equal 'Worked 1!', e.responses.first.body
    refute pipelining
  end

  def test_pipeline_check_ioerror
    @socket = Buffer.new IOError, true
    @socket.read_io.write http_response('Worked 1!')
    @socket.start

    requests = [@get1, @get2]
    responses = []

    assert_raises Net::HTTP::Pipeline::ResponseError do
      pipeline_check requests, responses
    end

    assert_equal [@get1, @get2], requests
    assert_equal 0, responses.length
    refute pipelining
  end

  def test_pipeline_check_non_persistent
    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!', 'Connection: close')
    @socket.start

    e = assert_raises Net::HTTP::Pipeline::PersistenceError do
      pipeline_check [@get1, @get2], []
    end

    assert_equal [@get2], e.requests
    assert_equal 1, e.responses.length
    assert_equal 'Worked 1!', e.responses.first.body
    refute pipelining
  end

  def test_pipeline_check_pipelining
    self.pipelining = true
    @socket = Buffer.new
    @socket.start

    requests = [@get1, @get2]
    responses = []

    pipeline_check requests, responses

    assert_equal [@get1, @get2], requests
    assert_empty responses
    assert pipelining
  end

  def test_pipeline_end_transport
    @curr_http_version = nil

    res = response

    @socket = StringIO.new

    pipeline_end_transport res

    refute @socket.closed?
    assert_equal '1.1', @curr_http_version
  end

  def test_pipeline_end_transport_no_keep_alive
    @curr_http_version = nil

    res = response
    res.header['connection'] = ['close']

    @socket = StringIO.new

    pipeline_end_transport res

    assert @socket.closed?
    assert_equal '1.1', @curr_http_version
  end

  def test_pipeline_keep_alive_eh
    res = response

    assert pipeline_keep_alive? res

    res.header['connection'] = ['close']

    refute pipeline_keep_alive? res
  end

  def test_pipeline_receive
    @socket = Buffer.new
    @socket.read_io.write http_response('Worked 1!')
    @socket.read_io.write http_response('Worked 2!')
    @socket.start

    in_flight = [@get1, @get2]
    responses = []

    r = pipeline_receive in_flight, responses

    @socket.finish

    refute @socket.closed?

    assert_equal 'Worked 1!', responses.first.body
    assert_equal 'Worked 2!', responses.last.body

    assert_same r, responses
  end

  def test_pipeline_receive_bad_response
    @socket = Buffer.new Errno::ECONNRESET
    @socket.read_io.write http_response('Worked 1!')
    @socket.start

    in_flight = [@get1, @get2]
    responses = []

    e = assert_raises Net::HTTP::Pipeline::ResponseError do
      pipeline_receive in_flight, responses
    end

    @socket.finish

    assert @socket.closed?

    assert_equal [@get2], e.requests
    assert_equal 1, e.responses.length
    assert_equal 'Worked 1!', e.responses.first.body

    assert_kind_of Errno::ECONNRESET, e.original
  end

  def test_pipeline_receive_ioerror
    @socket = Buffer.new IOError
    @socket.read_io.write http_response('Worked 1!')
    @socket.start

    in_flight = [@get1, @get2]
    responses = []

    e = assert_raises Net::HTTP::Pipeline::ResponseError do
      pipeline_receive in_flight, responses
    end

    @socket.finish

    assert @socket.closed?

    assert_equal [@get2], e.requests
    assert_equal 1, e.responses.length
    assert_equal 'Worked 1!', e.responses.first.body

    assert_kind_of IOError, e.original
  end

  def test_pipeline_receive_timeout
    @socket = Buffer.new Timeout::Error
    @socket.read_io.write http_response('Worked 1!')
    @socket.start

    in_flight = [@get1, @get2]
    responses = []

    e = assert_raises Net::HTTP::Pipeline::ResponseError do
      pipeline_receive in_flight, responses
    end

    @socket.finish

    assert @socket.closed?

    assert_equal [@get2], e.requests
    assert_equal 1, e.responses.length
    assert_equal 'Worked 1!', e.responses.first.body

    assert_kind_of Timeout::Error, e.original
  end

  def test_pipeline_send
    @socket = Buffer.new
    @socket.start

    requests = [@get1, @get2, @post, @get3]

    in_flight = pipeline_send requests

    @socket.finish

    assert_equal [@get1, @get2], in_flight
    assert_equal [@post, @get3], requests

    expected = ''
    expected << http_get * 2

    assert_equal expected, @socket.write_io.read
  end

  def test_pipeline_send_non_idempotent
    @socket = Buffer.new
    @socket.start

    requests = [@post, @get3]

    in_flight = pipeline_send requests

    @socket.finish

    assert_equal [@post], in_flight
    assert_equal [@get3], requests

    expected = http_post

    assert_equal expected, @socket.write_io.read
  end

end

