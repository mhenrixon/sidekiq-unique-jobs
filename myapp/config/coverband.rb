# Coverband.configure do |config|
#   config.store = Coverband::Adapters::RedisStore.new(Redis.new(url: ENV['MY_REDIS_URL']))
#   config.logger = Logger.new(STDOUT)
#   # configure S3 integration
#   # config.s3_bucket = 'coverband-demo'
#   # config.s3_region = 'us-east-1'
#   # config.s3_access_key_id = ENV['AWS_ACCESS_KEY_ID']
#   # config.s3_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
#   config.track_gems = true
#   config.gem_details = true

#   # config options false, true. (defaults to false)
#   # true and debug can give helpful and interesting code usage information
#   # and is safe to use if one is investigating issues in production, but it will slightly
#   # hit perf.
#   config.verbose = true

#   # default false. button at the top of the web interface which clears all data
#   config.web_enable_clear = true
#   # default false. Experimental support for tracking view layer tracking.
#   # Does not track line-level usage, only indicates if an entire file
#   # is used or not.
#   config.track_views = true
# end
