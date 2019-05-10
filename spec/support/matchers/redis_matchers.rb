# frozen_string_literal: true

require "rspec/expectations"
require "rspec/eventually"

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
      @within = ((seconds - @within)...(seconds + @within))
      @within.cover?(@pttl)
    else
      @actual = "#{key} with ttl(#{@ttl})"
      @ttl == seconds
    end
  end
  chain :within do |within|
    @within = within
  end
end

RSpec::Matchers.define :have_pttl do |ms|
  @within = 0
  match do |key|
    @pttl = pttl(key)
    if @within
      @actual = "#{key} with pttl(#{@pttl} +- #{@within})"
      @within = ((ms - @within)...(ms + @within))
      @within.cover?(@pttl)
    else
      @actual = "#{key} with pttl(#{@pttl})"
      @pttl == ms
    end
  end

  chain :within do |within|
    @within = within
  end
end

RSpec::Matchers.define :have_field do |field|
  match do |key|
    hget(key, field) == @value
  end

  chain :with do |value|
    @value = value
  end
end

module SidekiqUniqueJobs
  module Matchers
    def be_processed_in(expected_queue)
      BeProcessedIn.new(expected_queue)
    end

    class HaveMember
      def initialize(expected_queue)
        @expected_queue = expected_queue
      end

      def with(value)
        @value = value
        self
      end

      def description
        "be processed in the \"#{@expected_queue}\" queue"
      end

      def failure_message
        "expected #{@klass} to be processed in the \"#{@expected_queue}\" queue but got \"#{@actual}\""
      end

      def matches?(job)
        @klass = job.is_a?(Class) ? job : job.class
        @actual = if @klass.methods.include?(:get_sidekiq_options)
                    @klass.get_sidekiq_options["queue"]
                  else
                    job.try(:queue_name)
                  end
        @actual.to_s == @expected_queue.to_s
      end

      def failure_message_when_negated
        "expected #{@klass} to not be processed in the \"#{@expected_queue}\" queue"
      end
    end
  end
end

RSpec::Matchers.define :have_member do |member|
  @count = 1
  @value = nil
  @rank  = nil
  @score = nil
  match do |key|
    case type(key)
    when "string"
      valid_string_member?(key, member)
    when "hash"
      valid_hash_member?(key, member, @value)
    when "list"
      valid_list_member?(key, member, @index)
    when "set"
      valid_set_member?(key, member, @value)
    when "zset"
      valid_zset_member?(key, member, @value, @score, @rank)
    when "none"
      false
    else
      raise "Hell"
    end
  end

  def valid_string_member?(key, value)
    get(key) == value
  end

  def valid_hash_member?(key, member, value)
    hexists(key, member) &&
      (value.nil? || hget(key, member) == value)
  end

  def valid_zset_member?(key, member, _value, score = nil, _rank = nil)
    zrange(key, 0, -1, :withscores).to_a.any? { |pair| pair[0] == member && score.nil? || pair[1] == score }
  end

  def valid_set_member?(key, member)
    sismember(key, member)
  end

  def valid_list_member?(key, member, index)
    if index
      lindex(key, index) == member
    else
      lrange(key, 0, -1).include?(member)
    end
  end

  chain :atindex do |index|
    @index = index
  end

  chain :with_value do |value|
    @value = value
  end

  chain :with_rank do |rank|
    @rank = rank
  end

  chain :with_score do |score|
    @score = score
  end
end
