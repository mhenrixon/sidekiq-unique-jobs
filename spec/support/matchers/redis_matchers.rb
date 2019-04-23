# frozen_string_literal: true

require "rspec/expectations"
require "rspec/eventually"

RSpec::Matchers.define :be_enqueued_in do |queue|
  SidekiqUniqueJobs.redis do |conn|
    @actual = conn.llen("queue:#{queue}")
    match do |count_in_queue|
      @expected = count_in_queue
      expect(@actual).to eq(@expected)
    end
    diffable
  end
end

RSpec::Matchers.define :be_scheduled_at do |time|
  SidekiqUniqueJobs.redis do |conn|
    @actual = conn.zcount("schedule", -1, time)

    match do |count_in_queue|
      @expected = count_in_queue
      expect(@actual).to eq(@expected)
    end
    diffable
  end
end
