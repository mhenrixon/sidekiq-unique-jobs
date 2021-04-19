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
  let(:item_one) do
    {
      "jid" => jid_one,
      "lock_digest" => digest,
      "lock_ttl" => lock_ttl,
      "lock" => lock_type,
      "lock_timeout" => lock_timeout,
      "lock_limit" => lock_limit,
    }
  end
  let(:item_two) { item_one.merge("jid" => jid_two) }

  describe "#to_s" do
    subject(:to_s) { locksmith_one.to_s }

    it "outputs a helpful string" do
      expect(to_s).to eq(
        "Locksmith##{locksmith_one.object_id}" \
        "(digest=#{digest} job_id=#{jid_one}, locked=false)",
      )
    end
  end

  describe "#inspect" do
    subject(:inspect) { locksmith_one.inspect }

    it "outputs a helpful string" do
      expect(inspect).to eq(
        "Locksmith##{locksmith_one.object_id}" \
        "(digest=#{digest} job_id=#{jid_one}, locked=false)",
      )
    end
  end

  describe "#==" do
    subject(:==) { locksmith_one == comparable_locksmith } # rubocop:disable RSpec/VariableName

    context "when locksmiths are comparable" do
      let(:comparable_locksmith) { locksmith_one.dup }

      it { is_expected.to eq(true) }
    end

    context "when locksmiths are incomparable" do
      let(:comparable_locksmith) { locksmith_two }

      it { is_expected.to eq(false) }
    end
  end

  shared_examples_for "a lock" do
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
      locksmith_one.lock do
        code_executed = true
      end
      expect(code_executed).to eq(true)
    end

    context "when exceptions is raised" do
      let(:error_class)   { Exception }
      let(:error_message) { "redis lock exception" }
      let(:block)         { -> { raise error_class, error_message } }

      context "when given a block" do
        before do
          allow(locksmith_one).to receive(:lock_async) { block.call }
        end

        it "cleans up the lock" do
          expect { locksmith_one.lock(&block) }
            .to raise_error(error_class, error_message)

          expect(locksmith_one).not_to be_locked # if lock_ttl.nil?
        end
      end

      context "when given no block" do
        before do
          allow(locksmith_one).to receive(:lock_sync) { block.call }
        end

        it "cleans up the lock" do
          expect { locksmith_one.lock }
            .to raise_error(error_class, error_message)

          expect(locksmith_one).not_to be_locked # if lock_ttl.nil?
        end
      end
    end

    it "returns the value of the block if block-style locking is used" do
      block_value = locksmith_one.lock do
        42
      end

      expect(block_value).to eq(42)
    end

    it "disappears without a trace when calling `delete!`" do
      locksmith_one.lock
      locksmith_two.delete!

      expect(locksmith_one).not_to be_locked
    end

    context "when lock_timeout is zero" do
      let(:lock_timeout) { 0 }

      it "does not block" do
        did_we_get_in = false

        locksmith_one.lock do
          locksmith_two.lock do
            did_we_get_in = true
          end
        end

        expect(did_we_get_in).to be false
      end

      it "is locked" do
        locksmith_one.lock do
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
        expect(locksmith_one.delete).to eq(nil)

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
      locksmith_one.lock do
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

      locksmith_one.lock do
        locksmith_two.lock do
          did_we_get_in = true
        end
      end

      expect(did_we_get_in).to be false
    end
  end

  context "when silence_lock_timeout is false" do
    let(:logger) { Logger.new("/dev/null") }

    around do |example|
      SidekiqUniqueJobs.use_config(silence_lock_timeout: false, logger: logger, &example)
    end

    it "warns about not being able to obtain a lock" do
      allow(logger).to receive(:warn)

      locksmith_one.lock do
        locksmith_two.lock
      end

      expect(logger).to have_received(:warn).with(
        "Timed out after 0s while waiting for primed token (digest: uniquejobs:randomvalue, job_id: jidmayhem)",
      )
    end
  end

  context "when silence_lock_timeout is true" do
    let(:logger) { Logger.new("/dev/null") }

    around do |example|
      SidekiqUniqueJobs.use_config(silence_lock_timeout: true, logger: logger, &example)
    end

    it "does not warn about not being able to obtain a lock" do
      allow(logger).to receive(:warn)

      locksmith_one.lock do
        locksmith_two.lock
      end

      expect(logger).not_to have_received(:warn)
    end
  end
end
