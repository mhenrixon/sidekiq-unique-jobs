# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting, redis: :redis, redis_db: 3 do
  include SidekiqHelpers

  let!(:client_lock_one) { described_class.new(item_one) }
  let!(:server_lock_one) { described_class.new(item_one.dup) }

  let!(:client_lock_two) { described_class.new(item_two.dup) }
  let!(:server_lock_two) { described_class.new(item_two.dup) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:worker_class) { UntilAndWhileExecutingJob }
  let(:unique)       { :until_and_while_executing }
  let(:queue)        { :working }
  let(:args)         { %w[array of arguments] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { 'jid' => jid_one,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => unique,
      'args' => args }
  end
  let(:item_two) do
    { 'jid' => jid_two,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => unique,
      'args' => args }
  end

  describe '#execute' do
    context 'when job is being processed' do
      it 'moves subsequent jobs to dead queue' do
        expect(client_lock_one.lock).to eq(jid_one)
        expect(client_lock_one.locked?).to eq(true)
        expect(client_lock_one.unlock).to eq(1)
        expect(server_lock_one.locked?).to eq(false)

        server_lock_one.execute(callback) do
          expect(client_lock_one.locked?).to eq(false)
          expect(server_lock_one.locked?).to eq(true)
          expect(server_lock_two.locked?).to eq(false)
          # expect { server_lock_two.execute(callback) {} }
          #   .to change { dead_count }.from(0).to(1)

          expect(client_lock_two.lock).to eq(nil)
        end
      end
    end
  end
end
