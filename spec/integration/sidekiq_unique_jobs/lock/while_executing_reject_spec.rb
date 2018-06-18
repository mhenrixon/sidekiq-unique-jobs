# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecutingReject, redis: :redis do
  include SidekiqHelpers

  let(:client_middleware) { SidekiqUniqueJobs::Client::Middleware.new }
  let(:server_middleware) { SidekiqUniqueJobs::Server::Middleware.new }

  let(:jid)          { 'randomvalue' }
  let(:worker_class) { WhileExecutingRejectJob }
  let(:unique)       { :while_executing_reject }
  let(:queue)        { :rejecting }
  let(:item) do
    { 'jid' => jid,
      'class' => worker_class.to_s,
      'queue' => queue,
      'unique' => :while_executing_reject,
      'args' => %w[array of arguments] }
  end

  context 'when job is being processed' do
    it 'moves subsequent jobs to dead queue' do
      server_middleware.call(worker_class.new, item, queue) do
        expect(dead_count).to eq(0)
        expect { server_middleware.call(worker_class, item, queue) {} }
          .to change { dead_count }.from(0).to(1)
      end
    end
  end
end
