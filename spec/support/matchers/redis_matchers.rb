# frozen_string_literal: true

require "rspec/expectations"

RSpec::Matchers.define :have_enqueued do |number_of_jobs|
  SidekiqUniqueJobs.redis do |_conn|
    # @actual = conn.llen("queue:#{queue}")

    match do |queue|
      @actual = queue_count(queue)
      @expected = number_of_jobs
      @actual == @expected
    end
  end
end

RSpec::Matchers.define :be_enqueued_in do |queue|
  SidekiqUniqueJobs.redis do |conn|
    @actual = conn.llen("queue:#{queue}")
    match do |count_in_queue|
      @expected = count_in_queue
      expect(@actual).to eq(@expected)
    end
  end
end

RSpec::Matchers.define :be_scheduled do |_queue|
  SidekiqUniqueJobs.redis do |conn|
    @actual = conn.llen("queue:schedule")
    match do |count_in_queue|
      @expected = count_in_queue
      expect(@actual).to eq(@expected)
    end
  end
end

RSpec::Matchers.define :be_scheduled_at do |time|
  SidekiqUniqueJobs.redis do |conn|
    @actual = conn.zcount("schedule", -1, time)
    match do |count_in_queue|
      @expected = count_in_queue
      @actual == @expected
    end
  end
end

RSpec::Matchers.define :have_ttl do |seconds|
  @within = 0
  match do |key|
    @ttl = ttl(key)
    if @within
      @actual = "#{key} with ttl(#{@ttl} +- #{@within})"
      @range = ((seconds - @within)...(seconds + @within))
      @range.cover?(@ttl) ||
        (@within.between?(0, 1) && seconds.between?(0, 1)) # weird edge case
    else
      @actual = "#{key} with ttl(#{@ttl})"
      @ttl == seconds
    end
  end

  chain :within do |within|
    @within = within
  end
end
