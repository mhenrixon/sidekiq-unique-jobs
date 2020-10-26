# frozen_string_literal: true

RSpec.describe SimpleCov::Formatter::OjFormatter do
  let(:formatter)         { described_class.new }
  let(:result)            { instance_double(SimpleCov::Result) }
  let(:command_name)      { 'RSpec' }
  let(:created_at)        { Time.now.to_s }
  let(:foo)               { instance_double(SimpleCov::SourceFile) }
  let(:foo_line_list)     { instance_double(Array) }
  let(:foo_coverage_data) { [1, nil, 0, 0, nil, 1, nil] }
  let(:bar)               { instance_double(SimpleCov::SourceFile) }
  let(:bar_line_list)     { instance_double(Array) }
  let(:bar_coverage_data) { [nil, 1, nil, 1, 1, 1, 0, 0, nil, 1, nil] }

  describe '#format' do
    subject(:format) { formatter.format(result) }

    let(:expected_hash) do
      {
        'timestamp' => created_at.to_i,
        'command_name' => 'RSpec',
        'files' => [
          { 'filename' => '/lib/foo.rb',
            'covered_percent' => 50.0,
            'coverage' => [1, nil, 0, 0, nil, 1, nil],
            'covered_strength' => 0.50,
            'covered_lines' => 2,
            'lines_of_code' => 4 },
          { 'filename' => '/lib/bar.rb',
            'covered_percent' => 71.42,
            'coverage' => [nil, 1, nil, 1, 1, 1, 0, 0, nil, 1, nil],
            'covered_strength' => 0.71,
            'covered_lines' => 5,
            'lines_of_code' => 7 }
        ],
        'metrics' => {
          'covered_percent' => 73.33,
          'covered_strength' => 0.87,
          'covered_lines' => 11,
          'total_lines' => 15
        }
      }.to_json
    end

    before do
      allow(result).to receive(:created_at).and_return(created_at)
      allow(result).to receive(:command_name).and_return(command_name)
      allow(result).to receive(:covered_lines).and_return(11)
      allow(result).to receive(:covered_percent).and_return(73.33)
      allow(result).to receive(:covered_strength).twice.and_return(0.87)
      allow(result).to receive(:files).and_return([foo, bar])
      allow(result).to receive(:filenames).twice.and_return(['/lib/foo.rb', '/lib/bar.rb'])
      allow(result).to receive(:total_lines).and_return(15)

      allow(foo).to receive(:filename).twice.and_return('/lib/foo.rb')
      allow(foo).to receive(:covered_percent).and_return(50.0)
      if SimpleCov::SourceFile.instance_methods.include?(:coverage_data)
        allow(foo).to receive(:coverage_data).and_return(foo_coverage_data)
      else
        allow(foo).to receive(:coverage).and_return(foo_coverage_data)
      end
      allow(foo).to receive(:covered_strength).twice.and_return(0.50)
      allow(foo).to receive(:covered_lines).and_return(foo_line_list)
      allow(foo).to receive(:lines_of_code).and_return(4)

      allow(foo_line_list).to receive(:count).and_return(2)

      allow(bar).to receive(:filename).twice.and_return('/lib/bar.rb')
      allow(bar).to receive(:covered_percent).and_return(71.42)
      if SimpleCov::SourceFile.instance_methods.include?(:coverage_data)
        allow(bar).to receive(:coverage_data).and_return(bar_coverage_data)
      else
        allow(bar).to receive(:coverage).and_return(bar_coverage_data)
      end
      allow(bar).to receive(:covered_strength).twice.and_return(0.71)
      allow(bar).to receive(:covered_lines).and_return(bar_line_list)
      allow(bar).to receive(:lines_of_code).and_return(7)

      allow(bar_line_list).to receive(:count).and_return(5)
    end

    it { is_expected.to be_json_eql(expected_hash) }

    context 'when coverage_data is a hash with the key `lines:`' do
      let(:foo_coverage_data) { { lines: [1, nil, 0, 0, nil, 1, nil] } }
      let(:bar_coverage_data) { { lines: [nil, 1, nil, 1, 1, 1, 0, 0, nil, 1, nil] } }

      it { is_expected.to be_json_eql(expected_hash) }
    end
  end
end
