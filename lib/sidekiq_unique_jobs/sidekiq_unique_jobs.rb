# frozen_string_literal: true

#
# Contains configuration and utility methods that belongs top level
#
# @author Mikael Henriksson <mikael@zoolutions.se>
module SidekiqUniqueJobs
  include SidekiqUniqueJobs::Connection
  extend SidekiqUniqueJobs::JSON

  module_function

  # The current configuration (See: {.configure} on how to configure)
  def config
    # Arguments here need to match the definition of the new class (see above)
    @config ||= SidekiqUniqueJobs::Config.default
  end

  # The current strategies
  # @return [Hash] the configured strategies
  def strategies
    config.strategies
  end

  # The current locks
  # @return [Hash] the configured locks
  def locks
    config.locks
  end

  # The current logger
  # @return [Logger] the configured logger
  def logger
    config.logger
  end

  # Set a new logger
  # @param [Logger] other a new logger
  def logger=(other)
    config.logger = other
  end

  # Change global configuration while yielding
  # @yield control to the caller
  def use_config(tmp_config)
    raise ::ArgumentError, "#{name}.#{__method__} needs a block" unless block_given?

    old_config = config.to_h
    configure(tmp_config)
    yield
    configure(old_config)
  end

  #
  # Enable SidekiqUniuqeJobs either temporarily in a block or for good
  #
  #
  # @return [true] when not given a block
  # @return [true, false] the previous value of enable when given a block
  #
  # @yieldreturn [void] temporarily enable sidekiq unique jobs while executing a block of code
  def enable!
    set_enabled(true, &block)
  end

  #
  # Disable SidekiqUniuqeJobs either temporarily in a block or for good
  #
  #
  # @return [false] when not given a block
  # @return [true, false] the previous value of enable when given a block
  #
  # @yieldreturn [void] temporarily disable sidekiq unique jobs while executing a block of code
  def disable!(&block)
    set_enabled(false, &block)
  end

  def set_enabled(enabled)
    if block_given?
      enabled_was = config.enabled
      config.enabled = enabled
      yield
      config.enabled = enabled_was
    else
      config.enabled = enabled
    end
  end

  # Configure the gem
  #
  # This is usually called once at startup of an application
  # @param [Hash] options global gem options
  # @option options [Integer] :default_lock_timeout (default is 0)
  # @option options [true,false] :enabled (default is true)
  # @option options [String] :unique_prefix (default is 'uniquejobs')
  # @option options [Logger] :logger (default is Sidekiq.logger)
  # @yield control to the caller when given block
  def configure(options = {})
    if block_given?
      yield config
    else
      options.each do |key, val|
        config.send("#{key}=", val)
      end
    end
  end

  def redis_version
    @redis_version ||= redis { |conn| conn.info("server")["redis_version"] }
  end
end
