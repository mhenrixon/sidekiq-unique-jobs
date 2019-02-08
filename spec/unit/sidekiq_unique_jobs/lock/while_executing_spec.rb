# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting do
  include_context "with a stubbed locksmith"
  let(:lock)     { described_class.new(item, callback) }
  let(:callback) { -> {} }

  let(:item) do
    { "jid" => "maaaahjid",
      "class" => "WhileExecutingJob",
      "lock" => "while_executing",
      "args" => [%w[array of arguments]] }
  end

  describe ".new" do
    specify do
      expect { described_class.new(item, callback) }
        .to change { item["unique_digest"] }
        .to a_string_ending_with(":RUN")
    end
  end

  describe "#lock" do
    subject { lock.lock }

    it { is_expected.to eq(true) }
  end

  describe "#execute" do
    subject(:execute) { lock.execute }

    before do
      allow(locksmith).to receive(:lock).with(0).and_return(token)
    end

    # context 'when lock is successful' do
    #   let(:token) { 'locked' }

    # it_behaves_like 'an executing lock with error handling'
    # end

    context "when lock fails" do
      let(:token) { nil }

      it do
        expect { |block| lock.execute(&block) }
          .not_to yield_control
      end
    end
  end
end
