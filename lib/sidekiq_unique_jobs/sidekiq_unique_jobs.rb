# frozen_string_literal: true

#
# Contains configuration and utility methods that belongs top level
#
# @author Mikael Henriksson <mikael@zoolutions.se>
module SidekiqUniqueJobs
  include SidekiqUniqueJobs::Connection

  module_function

  Config = Concurrent::MutableStruct.new(
    :default_lock_timeout,
    :enabled,
    :unique_prefix,
    :logger,
  )

  # The current configuration (See: {.configure} on how to configure)
  def config
    # Arguments here need to match the definition of the new class (see above)
    @config ||= Config.new(
      0,
      true,
      "uniquejobs",
      Sidekiq.logger,
    )
  end

  # The current logger
  # @return [Logger] the configured logger
  def logger
    config.logger
  end

  # :reek:ManualDispatch
  def with_context(context, &block)
    if logger.respond_to?(:with_context)
      logger.with_context(context, &block)
    elsif defined?(Sidekiq::Logging)
      Sidekiq::Logging.with_context(context, &block)
    end
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
