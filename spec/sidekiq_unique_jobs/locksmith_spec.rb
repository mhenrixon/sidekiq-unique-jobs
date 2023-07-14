# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Locksmith do
  let(:locksmith_one)   { described_class.new(item_one) }
  let(:locksmith_two)   { described_class.new(item_two) }

  let(:jid_one)      { "maaaahjid" }
  let(:jid_two)      { "jidmayhem" }
  let(:lock_ttl)     { nil }
  let(:lock_type)    { "until_executed" }
  let(:digest)       { "uniquejobs:randomvalue" }
  let(:key)          { SidekiqUniqueJobs::Key.new(digest) }
  let(:lock)         { SidekiqUniqueJobs::Lock.new(key) }
  let(:lock_timeout) { 0 }
  let(:lock_limit)   { 1 }
  let(:queue)        { "default" }
  let(:worker)       { "UntilExecutedJob" }
  let(:lock_args)    { ["abc"] }
  let(:item_one) do
    {
      "class" => "UntilExecutedJob",
      "jid" => jid_one,
      "lock" => lock_type,
      "lock_args" => lock_args,
      "lock_digest" => digest,
      "lock_limit" => lock_limit,
      "lock_timeout" => lock_timeout,
      "lock_ttl" => lock_ttl,
      "queue" => queue,
    }
  end
  let(:key_one)  { locksmith_one.key }
  let(:key_two)  { locksmith_two.key }
  let(:item_two) { item_one.merge("jid" => jid_two) }

  describe "#to_s" do
    subject(:to_string) { locksmith_one.to_s }

    it "outputs a helpful string" do
      expect(to_string).to eq(
        "Locksmith##{locksmith_one.object_id}" \
        "(digest=#{digest} job_id=#{jid_one} locked=false)",
      )
    end
  end

  describe "#inspect" do
    subject(:inspect) { locksmith_one.inspect }

    it "outputs a helpful string" do
      expect(inspect).to eq(
        "Locksmith##{locksmith_one.object_id}" \
        "(digest=#{digest} job_id=#{jid_one} locked=false)",
      )
    end
  end

  describe "#==" do
    subject(:==) { locksmith_one == comparable_locksmith } # rubocop:disable RSpec/VariableName

    context "when locksmiths are comparable" do
      let(:comparable_locksmith) { locksmith_one.dup }

      it { is_expected.to be(true) }
    end

    context "when locksmiths are incomparable" do
      let(:comparable_locksmith) { locksmith_two }

      it { is_expected.to be(false) }
    end
  end

  shared_examples_for "a lock" do
    context "when lock_info is turned on globally" do
      it "adds a key with information about the lock" do
        SidekiqUniqueJobs.use_config(lock_info: true) do
          locksmith_one.lock do
            expect(lock.info.value).to match(
              a_hash_including(
                "limit" => lock_limit,
                "type" => lock_type.to_s,
                "lock_args" => lock_args,
                "queue" => queue,
                "timeout" => lock_timeout,
                "ttl" => lock_ttl,
                "worker" => worker,
              ),
            )
          end
        end
      end
    end

    context "when lock_info is turned on in worker" do
      it "adds a key with information about the lock" do
        UntilExecutedJob.use_options(lock_info: true) do
          locksmith_one.lock do
            expect(lock.info.value).to match(
              a_hash_including(
                "limit" => lock_limit,
                "type" => lock_type.to_s,
                "lock_args" => lock_args,
                "queue" => queue,
                "timeout" => lock_timeout,
                "ttl" => lock_ttl,
                "worker" => worker,
              ),
            )
          end
        end
      end
    end

    it "is unlocked from the start" do
      expect(locksmith_one).not_to be_locked
    end

    it "locks and unlocks" do
      locksmith_one.lock
      expect(locksmith_one).to be_locked
      locksmith_one.unlock
      expect(locksmith_one).not_to be_locked if lock_ttl.nil?
    end

    it "does not lock twice as a mutex" do
      expect(locksmith_one.lock).to be_truthy
      expect(locksmith_two.lock).to be_falsey
    end

    it "executes the given code block" do
      code_executed = false
      locksmith_one.execute do
        code_executed = true
      end
      expect(code_executed).to be(true)
    end

    context "when exceptions is raised" do
      let(:error_class)   { Exception }
      let(:error_message) { "redis lock exception" }
      let(:block)         { -> { raise error_class, error_message } }

      context "when given a block" do
        before do
          allow(locksmith_one).to receive(:lock!) { block.call }
        end

        it "cleans up the lock" do
          expect { locksmith_one.lock(&block) }
            .to raise_error(error_class, error_message)

          expect(locksmith_one).not_to be_locked # if lock_ttl.nil?
        end
      end

      context "when given no block" do
        before do
          allow(locksmith_one).to receive(:lock!) { block.call }
        end

        it "cleans up the lock" do
          expect { locksmith_one.lock }
            .to raise_error(error_class, error_message)

          expect(locksmith_one).not_to be_locked # if lock_ttl.nil?
        end
      end
    end

    it "returns the value of the block if block-style locking is used" do
      block_value = locksmith_one.execute do
        42
      end

      expect(block_value).to eq(42)
    end

    it "disappears without a trace when calling `delete!`" do
      locksmith_one.lock
      locksmith_two.delete!

      expect(locksmith_one).not_to be_locked
    end

    it "allows deletion when call script returns a string" do
      locksmith_one.lock
      allow(locksmith_one).to receive(:call_script).and_return("120")
      locksmith_two.delete!

      expect(locksmith_one).not_to be_locked
    end

    context "when lock_timeout is zero" do
      let(:lock_timeout) { 0 }

      it "does not block" do
        did_we_get_in = false

        locksmith_one.execute do
          locksmith_two.execute do
            did_we_get_in = true
          end
        end

        expect(did_we_get_in).to be false
      end

      it "is locked" do
        locksmith_one.execute do
          expect(locksmith_one).to be_locked
        end

        expect(locksmith_one).not_to be_locked if lock_ttl.nil?
      end
    end
  end

  context "with lock_ttl" do
    let(:lock_ttl)  { 1 }
    let(:lock_type) { :while_executing }

    it_behaves_like "a lock"

    context "when lock_type is until_expired" do
      let(:lock_type) { :until_expired }

      it "prevents other processes from locking" do
        locksmith_one.lock

        sleep 0.1

        expect(locksmith_two.lock).to be_falsey
      end

      # it "reflects on timeout" do
      #   allow(locksmith_two).to receive(:reflect)
      #   locksmith_one.lock

      #   sleep 0.1

      #   expect(locksmith_two.lock).to be_falsey
      #   expect(locksmith_two).to have_received(:reflect).with(:timeout, item_two)
      # end

      it "expires the expected keys" do
        locksmith_one.lock
        locksmith_one.unlock

        expect(locksmith_one).to be_locked
      end
    end

    context "when lock_type is anything else than until_expired" do
      let(:lock_type) { :until_executed }

      it "expires the expected keys" do
        locksmith_one.lock
        expect(locksmith_one).to be_locked
        locksmith_one.unlock
        expect(locksmith_one).not_to be_locked
        expect(locksmith_one.delete).to be_nil

        expect(locksmith_one).not_to be_locked
      end
    end

    it "deletes the expected keys" do
      locksmith_one.lock
      expect(locksmith_one).to be_locked
      locksmith_one.delete!
      expect(locksmith_one).not_to be_locked
    end

    it "expires keys" do
      locksmith_one.lock
      keys = unique_keys
      expect(unique_keys).not_to include(keys)
    end

    it "expires keys after unlocking" do
      locksmith_one.execute do
        # noop
      end
      keys = unique_keys
      expect(unique_keys).not_to include(keys)
    end
  end

  context "when lock_timeout is 1" do
    let(:lock_timeout) { 1 }

    it "blocks other locks" do
      did_we_get_in = false

      locksmith_one.execute do
        locksmith_two.execute do
          did_we_get_in = true
        end
      end

      expect(did_we_get_in).to be false
    end

    it "waits for brpoplpush when resolving the promise" do
      allow(locksmith_one).to receive(:brpoplpush) do
        sleep(0.75)
        jid_one
      end

      did_we_get_in = false
      locksmith_one.execute do
        did_we_get_in = true
      end

      expect(locksmith_one).to have_received(:brpoplpush)
      expect(did_we_get_in).to be true
    end
  end

  # it "reflects" do
  #   allow(locksmith_one).to receive(:reflect)

  #   locksmith_one.lock
  #   expect(locksmith_one).to have_received(:reflect).with(:locked, item_one)

  #   locksmith_one.lock { "Reflecting" }
  #   expect(locksmith_one).to have_received(:reflect).with(:locked, item_one)
  #   expect(locksmith_one).to have_received(:reflect).with(:unlocked, item_one)
  # end

  # it "does not reflect" do
  #   allow(locksmith_two).to receive(:reflect).and_call_original

  #   expect(locksmith_one.lock).to eq("maaaahjid")
  #   expect(locksmith_two.lock).to eq(nil)
  #   expect(locksmith_two).to have_received(:reflect).with(:timeout, item_two)
  #   expect(locksmith_two).not_to have_received(:reflect).with(:locked, item_two)
  # end

  it "reflects on unlocked" do
    locksmith_one.lock
    allow(locksmith_one).to receive(:reflect)
    locksmith_one.unlock
    expect(locksmith_one).to have_received(:reflect).with(:unlocked, item_one)
  end
end
