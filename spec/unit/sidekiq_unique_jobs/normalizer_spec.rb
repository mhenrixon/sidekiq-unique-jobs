# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Normalizer do
  describe ".jsonify" do
    specify do
      original = [1, :test, [test: :test]]
      expected = [1, "test", ["test" => "test"]]
      expect(described_class.jsonify(original)).to eq(expected)
    end

    specify do
      original = [1, :test, [test: [test: :test]]]
      expected = [1, "test", ["test" => ["test" => "test"]]]
      expect(described_class.jsonify(original)).to eq(expected)
    end
  end
end
