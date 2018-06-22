# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject, redis: :redis do
  include SidekiqHelpers

  let(:client_lock_one) { described_class.new(item) }
  let(:server_lock_one) { described_class.new(item.dup) }
  let(:server_lock_two) { described_class.new(item.dup) }

  let(:jid)          { 'randomvalue' }
  let(:worker_class) { WhileExecutingRejectJob }
  let(:unique)       { :while_executing_reject }
  let(:queue)        { :rejecting }
  let(:callback)     { -> {} }
  let(:item) do
    { 'jid' => jid,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => :while_executing_reject,
      'args' => %w[array of arguments] }
  end

  context 'when job is being processed' do
    it 'moves subsequent jobs to dead queue' do
      expect(server_lock_one.locked?).to eq(false)
      server_lock_one.execute(callback) do
        expect(server_lock_one.locked?).to eq(true)
        expect(server_lock_two.locked?).to eq(false)
        expect(dead_count).to eq(0)
        expect { server_lock_two.execute(callback) {} }
          .to change { dead_count }.from(0).to(1)

        expect(server_lock_two.lock).to eq(true)
      end
    end
  end
end
