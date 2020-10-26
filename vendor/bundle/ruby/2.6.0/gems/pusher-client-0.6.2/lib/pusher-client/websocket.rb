require 'socket'
require 'websocket'
require 'openssl'

module PusherClient
  class PusherWebSocket
    WAIT_EXCEPTIONS  = [Errno::EAGAIN, Errno::EWOULDBLOCK]
    WAIT_EXCEPTIONS << IO::WaitReadable if defined?(IO::WaitReadable)

    CA_FILE = File.expand_path('../../../certs/cacert.pem', __FILE__)

    attr_accessor :socket

    def initialize(url, params = {})
      @hs ||= WebSocket::Handshake::Client.new(:url => url)
      @frame ||= WebSocket::Frame::Incoming::Server.new(:version => @hs.version)
      @socket = TCPSocket.new(@hs.host, @hs.port || 80)
      @cert_file = params[:cert_file]
      @logger = params[:logger] || PusherClient.logger

      if params[:ssl] == true
        ctx = OpenSSL::SSL::SSLContext.new
        if params[:ssl_verify]
          ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER|OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
          # http://curl.haxx.se/ca/cacert.pem
          ctx.ca_file = @cert_file || CA_FILE
        else
          ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        ssl_sock = OpenSSL::SSL::SSLSocket.new(@socket, ctx)
        ssl_sock.sync_close = true
        ssl_sock.connect

        @socket = ssl_sock
      end

      @socket.write(@hs.to_s)
      @socket.flush

      loop do
        data = @socket.getc
        next if data.nil?

        @hs << data

        if @hs.finished?
          raise @hs.error.to_s unless @hs.valid?
          @handshaked = true
          break
        end
      end
    end

    def send(data, type = :text)
      raise "no handshake!" unless @handshaked

      data = WebSocket::Frame::Outgoing::Client.new(
        :version => @hs.version,
        :data => data,
        :type => type
      ).to_s
      @socket.write data
      @socket.flush
    end

    def receive
      raise "no handshake!" unless @handshaked

      begin
        data = @socket.read_nonblock(1024)
      rescue *WAIT_EXCEPTIONS
        IO.select([@socket])
        retry
      end
      @frame << data

      messages = []
      while message = @frame.next
        if message.type === :ping
          send(message.data, :pong)
          return messages
        end
        messages << message.to_s
      end
      messages
    end

    def close
      @socket.close
    rescue IOError => error
      logger.debug error.message
    end

    private

    attr_reader :logger
  end
end
