require 'json'
require 'openssl'
require 'digest/md5'

module PusherClient
  class Socket

    CLIENT_ID = 'pusher-ruby-client'
    PROTOCOL = '6'

    attr_reader :path, :connected, :channels, :global_channel, :socket_id

    def initialize(app_key, options={})
      raise ArgumentError, "Missing app_key" if app_key.to_s.empty?

      @path = "#{options[:ws_path]}/app/#{app_key}?client=#{CLIENT_ID}&version=#{PusherClient::VERSION}&protocol=#{PROTOCOL}"
      @key = app_key.to_s
      @secret = options[:secret]
      @socket_id = nil
      @channels = Channels.new
      @global_channel = Channel.new('pusher_global_channel')
      @global_channel.global = true
      @connected = false
      @encrypted = options[:encrypted] || options[:secure] || false
      @logger = options[:logger] || PusherClient.logger
      # :private_auth_method is deprecated
      @auth_method = options[:auth_method] || options[:private_auth_method]
      @cert_file = options[:cert_file]
      @ws_host = options[:ws_host] || HOST
      @ws_port = options[:ws_port] || WS_PORT
      @wss_port = options[:wss_port] || WSS_PORT
      @ssl_verify = options.fetch(:ssl_verify, true)

      if @encrypted
        @url = "wss://#{@ws_host}:#{@wss_port}#{@path}"
      else
        @url = "ws://#{@ws_host}:#{@ws_port}#{@path}"
      end

      bind('pusher:connection_established') do |data|
        socket = parser(data)
        @connected = true
        @socket_id = socket['socket_id']
        subscribe_all
      end

      bind('pusher:connection_disconnected') do |data|
        @connected = false
        @channels.channels.each { |c| c.disconnect }
      end

      bind('pusher:error') do |data|
        logger.fatal("Pusher : error : #{data.inspect}")
      end

      # Keep this in case we're using a websocket protocol that doesn't
      # implement ping/pong
      bind('pusher:ping') do
        send_event('pusher:pong', nil)
      end
    end

    def connect(async = false)
      return if @connection
      logger.debug("Pusher : connecting : #{@url}")

      if async
        @connection_thread = Thread.new do
          begin
            connect_internal
          rescue => ex
            send_local_event "pusher:error", ex
          end
        end
      else
        connect_internal
      end
      self
    end

    def disconnect
      return unless @connection
      logger.debug("Pusher : disconnecting")
      @connected = false
      @connection.close
      @connection = nil
      if @connection_thread
        @connection_thread.kill
        @connection_thread = nil
      end
    end

    def subscribe(channel_name, user_data = nil)
      if user_data.is_a? Hash
        user_data = user_data.to_json
      elsif user_data
        user_data = {:user_id => user_data}.to_json
      elsif is_presence_channel(channel_name)
        raise ArgumentError, "user_data is required for presence channels"
      end

      channel = @channels.add(channel_name, user_data)
      if @connected
        authorize(channel, method(:authorize_callback))
      end
      return channel
    end

    def unsubscribe(channel_name)
      channel = @channels.remove channel_name
      if channel && @connected
        send_event('pusher:unsubscribe', {
          'channel' => channel_name
        })
      end
      return channel
    end

    def bind(event_name, &callback)
      @global_channel.bind(event_name, &callback)
      return self
    end

    def [](channel_name)
      @channels[channel_name] || NullChannel.new(channel_name)
    end

    def subscribe_all
      @channels.channels.clone.each { |k,v| subscribe(v.name, v.user_data) }
    end

    # auth for private and presence
    def authorize(channel, callback)
      if is_private_channel(channel.name)
        auth_data = get_private_auth(channel)
      elsif is_presence_channel(channel.name)
        auth_data = get_presence_auth(channel)
      end
      # could both be nil if didn't require auth
      callback.call(channel, auth_data, channel.user_data)
    end

    def authorize_callback(channel, auth_data, channel_data)
      send_event('pusher:subscribe', {
        'channel' => channel.name,
        'auth' => auth_data,
        'channel_data' => channel_data
      })
      channel.acknowledge_subscription(nil)
    end

    def is_private_channel(channel_name)
      channel_name.match(/^private-/)
    end

    def is_presence_channel(channel_name)
      channel_name.match(/^presence-/)
    end

    def get_private_auth(channel)
      return @auth_method.call(@socket_id, channel) if @auth_method

      string_to_sign = @socket_id + ':' + channel.name
      signature = hmac(@secret, string_to_sign)
      "#{@key}:#{signature}"
    end

    def get_presence_auth(channel)
      return @auth_method.call(@socket_id, channel) if @auth_method

      string_to_sign = @socket_id + ':' + channel.name + ':' + channel.user_data
      signature = hmac(@secret, string_to_sign)
      "#{@key}:#{signature}"
    end


    # for compatibility with JavaScript client API
    alias :subscribeAll :subscribe_all

    def send_event(event_name, data)
      payload = {'event' => event_name, 'data' => data}.to_json
      @connection.send(payload)
      logger.debug("Pusher : sending event : #{payload}")
    end

    def send_channel_event(channel, event_name, data)
      payload = {'channel' => channel, 'event' => event_name, 'data' => data}.to_json
      @connection.send(payload)
      logger.debug("Pusher : sending channel event : #{payload}")
    end

  protected

    attr_reader :logger

    def connect_internal
      @connection = PusherWebSocket.new(@url, {
        :ssl => @encrypted,
        :cert_file => @cert_file,
        :ssl_verify => @ssl_verify
      })

      logger.debug("Websocket connected")

      loop do
        @connection.receive.each do |msg|
          params = parser(msg)

          # why ?
          next if params['socket_id'] && params['socket_id'] == self.socket_id

          send_local_event(params['event'], params['data'], params['channel'])
        end
      end
    end

    def send_local_event(event_name, event_data, channel_name=nil)
      if channel_name
        channel = @channels[channel_name]
        if channel
          channel.dispatch_with_all(event_name, event_data)
        end
      end

      @global_channel.dispatch_with_all(event_name, event_data)
      logger.debug("Pusher : event received : channel: #{channel_name}; event: #{event_name}")
    end

    def parser(data)
      return data if data.is_a? Hash
      return JSON.parse(data)
    rescue => err
      logger.warn(err)
      logger.warn("Pusher : data attribute not valid JSON - you may wish to implement your own Pusher::Client.parser")
      return data
    end

    def hmac(secret, string_to_sign)
      digest = OpenSSL::Digest::SHA256.new
      signature = OpenSSL::HMAC.hexdigest(digest, secret, string_to_sign)
    end
  end

end
