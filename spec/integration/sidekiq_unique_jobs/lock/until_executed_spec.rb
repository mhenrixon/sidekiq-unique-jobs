# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExecuted, redis: :redis do
  include SidekiqHelpers

  let(:client_lock_one) { described_class.new(item_one) }
  let(:server_lock_one) { described_class.new(item_one.dup) }

  let(:client_lock_two) { described_class.new(item_two) }
  let(:server_lock_two) { described_class.new(item_two.dup) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:worker_class) { WhileExecutingRejectJob }
  let(:unique)       { :while_executing_reject }
  let(:queue)        { :rejecting }
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
    it 'locks until execute is completed' do
      expect(client_lock_one.lock).to eq(jid_one)
      expect(client_lock_one.locked?).to eq(true)
      expect(server_lock_one.locked?).to eq(true)

      server_lock_one.execute(callback) do
        expect(server_lock_one.locked?).to eq(true)
        expect(client_lock_one.locked?).to eq(true) # same jid as server_lock_one

        expect(server_lock_two.locked?).to eq(false)
        expect(client_lock_two.locked?).to eq(false)

        expect(client_lock_two.lock).to eq(nil)
        expect(server_lock_two.lock).to eq(nil)

        unset = true
        server_lock_two.execute(callback) do
          unset = false
        end

        expect(unset).to eq(true)
      end

      expect(client_lock_one.locked?).to eq(false)
      expect(server_lock_one.locked?).to eq(false)
    end
  end
end
