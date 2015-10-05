require 'spec_helper'

RSpec.describe Hash do
  subject { { test: :me, not: :me } }

  describe '#slice' do
    specify { expect(subject.slice(:test)).to eq(test: :me) }
  end

  describe '#slice!' do
    specify { expect { subject.slice!(:test) }.to change { subject }.to(test: :me) }
  end
end

RSpec.describe String do
  describe '#classify' do
    subject { 'under_scored_string' }
    its(:classify) { is_expected.to eq('UnderScoredString') }
  end

  describe '#camelize' do
    subject { 'under_scored_string' }
    its(:camelize) { is_expected.to eq('UnderScoredString') }
  end
end
