require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::OptionsWithFallback do
  include described_class
  subject { self }

  let(:options) { {} }
  let(:item) { {} }

  describe '#unique_lock' do
    context 'when options have `unique: true`' do
      let(:options) { { 'unique' => true } }

      it 'warns when unique is set to true' do
        expect(subject)
          .to receive(:warn)
          .with("unique: true is no longer valid. Please set it to the type of lock required like: `unique: :until_executed`")

        subject.unique_lock
      end
    end
  end
end
