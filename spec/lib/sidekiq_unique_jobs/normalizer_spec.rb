require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Normalizer do
  def jsonify(args)
    described_class.jsonify(args)
  end

  describe '.jsonify' do
    specify do
      original = [1, :test, [test: :test]]
      expected = [1, 'test', ['test' => 'test']]
      expect(jsonify(original)).to eq(expected)
    end

    specify do
      original = [1, :test, [test: [test: :test]]]
      expected = [1, 'test', ['test' => ['test' => 'test']]]
      expect(jsonify(original)).to eq(expected)
    end
  end
end
