# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Middleware::Client, redis_db: 1 do
  describe "when a job is already scheduled" do
    it "processes jobs properly" do
      jid = NotifyWorker.perform_in(1, 183, "xxxx")
      expect(jid).not_to eq(nil)

      expect(schedule_count).to eq(1)

      expected = %w[
        uniquejobs:26a33855311a0a653c5e0b4af1d1458d
      ]

      expect(keys).to include(*expected)
    end

    it "rejects nested subsequent jobs with the same arguments" do
      expect(SimpleWorker.perform_async(1)).not_to eq(nil)
      expect(SimpleWorker.perform_async(1)).to eq(nil)
      expect(SimpleWorker.perform_in(60, 1)).to eq(nil)
      expect(SimpleWorker.perform_in(60, 1)).to eq(nil)
      expect(SimpleWorker.perform_in(60, 1)).to eq(nil)
      expect(schedule_count).to eq(0)
      expect(SpawnSimpleWorker.perform_async(1)).not_to eq(nil)

      expect(queue_count("default")).to eq(1)
      expect(queue_count("not_default")).to eq(1)
    end

    it "schedules new jobs when arguments differ" do
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
        MainJob.perform_in(x, x)
      end

      expect(schedule_count).to eq(20)
    end

    it "schedules allows jobs to be scheduled " do
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
        PlainClass.delay_for(x, queue: "default", unique: :while_executing).run(1)
      end

      expect(schedule_count).to eq(20)
    end
  end

  it "does not push duplicate messages when unique_args are filtered with a proc" do
    Array.new(10) { MyUniqueJobWithFilterProc.perform_async(1) }
    expect(queue_count("customqueue")).to eq(1)

    flush_redis
    expect(queue_count("customqueue")).to eq(0)

    Array.new(10) do
      push_item(
        "class" => MyUniqueJobWithFilterProc,
        "queue" => "customqueue",
        "args" => [1, { type: "value", some: "not used" }],
      )
    end

    expect(queue_count("customqueue")).to eq(1)
  end

  it "does not push duplicate messages when unique_args are filtered with a method" do
    Array.new(10) { MyUniqueJobWithFilterMethod.perform_async(1) }

    expect(queue_count("customqueue")).to eq(1)
    flush_redis
    expect(queue_count("customqueue")).to eq(0)

    Array.new(10) do
      push_item(
        "class" => MyUniqueJobWithFilterMethod,
        "queue" => "customqueue",
        "args" => [1, { type: "value", some: "not used" }],
      )
    end

    expect(queue_count("customqueue")).to eq(1)
  end

  it "does not queue duplicates when when calling delay" do
    Array.new(10) { PlainClass.delay(lock: :until_executed, queue: "customqueue").run(1) }

    expect(queue_count("customqueue")).to eq(1)
  end

  context "when class is not unique" do
    it "pushes duplicate messages" do
      Array.new(10) do
        push_item("class" => CustomQueueJob, "queue" => "customqueue", "args" => [1, 2])
      end

      expect(queue_count("customqueue")).to eq(10)
    end
  end

  describe "when lock_args_method is defined" do
    context "when filter method is defined" do
      it "pushes no duplicate messages" do
        expect(CustomQueueJobWithFilterMethod).to respond_to(:args_filter)
        expect(CustomQueueJobWithFilterMethod.get_sidekiq_options["lock_args_method"]).to eq :args_filter

        Array.new(10) do |i|
          push_item(
            "class" => CustomQueueJobWithFilterMethod,
            "queue" => "customqueue",
            "args" => [1, i],
          )
        end

        expect(queue_count("customqueue")).to eq(1)
        # NOTE: Below is for regression purposes
        expect(Sidekiq::Queue.new("customqueue").entries.first.item["lock_args"]).to eq(1)
      end
    end

    context "when filter proc is defined" do
      let(:args) { [1, { "random" => rand, "name" => "foobar" }] }

      it "pushes no duplicate messsages" do
        Array.new(100) { CustomQueueJobWithFilterProc.perform_async(*args) }

        expect(queue_count("customqueue")).to eq(1)
        # NOTE: Below is for regression purposes
        expect(Sidekiq::Queue.new("customqueue").entries.first.item["lock_args"]).to eq([1, "foobar"])
      end
    end

    context "when unique_across_queues is set" do
      it "pushes no duplicate messages on other queues" do
        item = { "class" => UniqueOnAllQueuesJob, "args" => [1, 2] }
        push_item(item.merge("queue" => "customqueue"))
        push_item(item.merge("queue" => "customqueue2"))

        expect(queue_count("customqueue")).to eq(1)
        expect(queue_count("customqueue2")).to eq(0)
      end
    end

    context "when unique_across_workers is set" do
      it "does not push duplicate messages for other workers" do
        item_one = {
          "queue" => "customqueue1",
          "class" => UniqueAcrossWorkersJob,
          "unique_across_workers" => true,
          "args" => [1, 2],
        }

        item_two = {
          "queue" => "customqueue1",
          "class" => MyUniqueJob,
          "unique_across_workers" => true,
          "args" => [1, 2],
        }

        push_item(item_one)
        push_item(item_two)

        expect(queue_count("customqueue1")).to eq(1)
      end
    end
  end

  it "expires the digest when a scheduled job is scheduled at" do
    expected_expires_at = Time.now.to_i + 15 * 60 - Time.now.utc.to_i

    MyUniqueJob.perform_in(expected_expires_at, "mika", "hel")

    unique_keys.all? do |key|
      next if key.end_with?(":INFO")

      expect(key).to have_ttl(8_100)
    end
  end
end
