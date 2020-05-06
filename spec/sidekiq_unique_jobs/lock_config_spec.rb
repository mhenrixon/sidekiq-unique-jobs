# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::LockConfig do
  subject { lock_config }

  let(:lock_config) { described_class.new(job_hash) }

  let(:item) do
    {
      lock: lock_type,
      class: worker_class,
      lock_limit: lock_limit,
      lock_timeout: lock_timeout,
      lock_ttl: lock_ttl,
      lock_info: lock_info,
      on_conflict: on_conflict,
      errors: errors,
    }
  end

  let(:job_hash) { item.stringify_keys }

  let(:lock_type)    { :until_executed }
  let(:worker_class) { "UntilExecutedJob" }
  let(:lock_limit)   { 2 }
  let(:lock_timeout) { 5 }
  let(:lock_ttl)     { 2000 }
  let(:lock_info)    { true }
  let(:on_conflict)  { :log }
  let(:errors)       { {} }

  its(:type)        { is_expected.to eq(lock_type) }
  its(:worker)      { is_expected.to eq(worker_class) }
  its(:limit)       { is_expected.to eq(lock_limit) }
  its(:timeout)     { is_expected.to eq(lock_timeout) }
  its(:ttl)         { is_expected.to eq(lock_ttl) }
  its(:lock_info)   { is_expected.to eq(lock_info) }
  its(:on_conflict) { is_expected.to eq(on_conflict) }
  its(:errors)      { is_expected.to eq({}) }

  describe "#wait_for_lock?" do
    subject(:wait_for_lock?) { lock_config.wait_for_lock? }

    context "when timeout is nil" do
      let(:lock_timeout) { nil }

      it { is_expected.to eq(true) }
    end

    context "when timeout is positive?" do
      let(:lock_timeout) { 3 }

      it { is_expected.to eq(true) }
    end

    context "when timeout is zero?" do
      let(:lock_timeout) { 0 }

      it { is_expected.to eq(false) }
    end
  end

  describe "#valid?" do
    subject(:valid?) { lock_config.valid? }

    it { is_expected.to eq(true) }

    context "when errors are present" do
      let(:errors) { { any: :thing } }

      it { is_expected.to eq(false) }
    end
  end

  describe "#on_client_conflict" do
    subject(:on_client_conflict) { lock_config.on_client_conflict }

    it { is_expected.to eq(:log) }

    context "when on_conflict is a hash" do
      let(:on_conflict) { { client: :replace, server: :reschedule } }

      it { is_expected.to eq(:replace) }
    end
  end

  describe "#on_server_conflict" do
    subject(:on_server_conflict) { lock_config.on_server_conflict.to_sym }

    let(:job_hash) { ::JSON.parse(item.to_json) }

    it { is_expected.to eq(:log) }

    context "when on_conflict is a hash" do
      let(:on_conflict) { { client: :replace, server: :reschedule } }

      it { is_expected.to eq(:reschedule) }
    end
  end
end
