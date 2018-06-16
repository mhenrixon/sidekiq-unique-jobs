# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'core_ext.rb' do
  describe Hash do
    subject(:hash) { { test: :me, not: :me } }

    describe '#slice' do
      specify { expect(hash.slice(:test)).to eq(test: :me) }
    end

    describe '#slice!' do
      specify { expect { hash.slice!(:test) }.to change { hash }.to(test: :me) }
    end
  end
end
