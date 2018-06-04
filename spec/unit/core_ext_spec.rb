# frozen_string_literal: true

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
