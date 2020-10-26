# This test isn't part of the actual suite it's to manually test the formatters.
require 'nc'

RSpec.describe 'to test the gem' do
  it 'passes' do
    expect(0).to eq 0
  end

  it 'fails' do
    expect(1).to eq 2
  end

  it 'fails again' do
    expect(3).to eq 4
  end

  it 'pending' do
    pending 'for a reason'
    expect(5).to eq 6
  end
end
