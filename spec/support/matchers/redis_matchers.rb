# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :be_enqueued_in do |queue|
  SidekiqUniqueJobs.connection do |conn|
    @actual = conn.llen("queue:#{queue}")
    match do |count_in_queue|
      @expected = count_in_queue
      expect(@actual).to eq(@expected)
    end
    diffable
  end
end

RSpec::Matchers.define :be_scheduled_at do |time|
  SidekiqUniqueJobs.connection do |conn|
    @actual = conn.zcount('schedule', -1, time)

    match do |count_in_queue|
      @expected = count_in_queue
      expect(@actual).to eq(@expected)
    end
    diffable
  end
end

RSpec::Matchers.define :have_key do |_unique_key|
  Sidekiq.redis do |conn|
    match do |_unique_jobs|
      @value       = conn.get(@unique_key)
      @ttl         = conn.ttl(@unique_key)

      @value && with_value && for_seconds
    end

    chain :with_value do |value = nil|
      @expected_value = value
      @expected_value && @value == @expected_value
    end

    chain :for_seconds do |ttl = nil|
      @expected_ttl = ttl
      @expected_ttl && @ttl == @expected_ttl
    end

    failure_message do |_actual|
      msg = "expected Redis to have key #{@unique_key}"
      msg += " with value #{@expected_value} was (#{@value})" if @expected_value
      msg += " with value #{@expected_ttl} was (#{@ttl})" if @expected_ttl
      msg
    end
  end
end
