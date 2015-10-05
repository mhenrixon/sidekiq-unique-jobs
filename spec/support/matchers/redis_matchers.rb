require 'rspec/expectations'

RSpec::Matchers.define :have_key do |unique_key|
  Sidekiq.redis do |redis|
    match do |_actual|
      with_value && for_seconds
    end

    chain :with_value do |value = nil|
      value.nil? ||
        redis.get(unique_key) == value
    end

    chain :for_seconds do |ttl = nil|
      ttl.nil? ||
        redis.ttl(unique_key) == ttl
    end
  end
end
