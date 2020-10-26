module PusherClient

  class Channel
    attr_accessor :global, :subscribed
    attr_reader :name, :callbacks, :user_data

    def initialize(channel_name, user_data=nil, logger=PusherClient.logger)
      @name = channel_name
      @user_data = user_data
      @logger = logger
      @global = false
      @callbacks = {}
      @subscribed = false
    end

    def bind(event_name, &callback)
      PusherClient.logger.debug "Binding #{event_name} to #{name}"
      @callbacks[event_name] = callbacks[event_name] || []
      @callbacks[event_name] << callback
      return self
    end

    def dispatch_with_all(event_name, data)
      dispatch(event_name, data)
    end

    def dispatch(event_name, data)
      logger.debug("Dispatching #{global ? 'global ' : ''}callbacks for #{event_name}")
      if @callbacks[event_name]
        @callbacks[event_name].each do |callback|
          callback.call(data)
        end
      else
        logger.debug "No #{global ? 'global ' : ''}callbacks to dispatch for #{event_name}"
      end
    end

    def acknowledge_subscription(data)
      @subscribed = true
    end

    private

    attr_reader :logger
  end

  class NullChannel
    def initialize(channel_name, *a)
      @name = channel_name
    end
    def method_missing(*a)
      raise ArgumentError, "Channel `#{@name}` hasn't been subscribed yet."
    end
  end

end
