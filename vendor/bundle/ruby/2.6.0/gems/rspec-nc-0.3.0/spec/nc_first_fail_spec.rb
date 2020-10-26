require 'nc_first_fail'

describe NcFirstFail do
  let(:formatter)   { NcFirstFail.new(StringIO.new) }
  let(:current_dir) { File.basename(File.expand_path '.') }
  let(:failure_count) { 1 }
  let(:summary_notification) do
    instance_double(RSpec::Core::Notifications::SummaryNotification,
      formatted_duration: '0.0001 seconds',
      totals_line: '3 examples, 1 failure, 1 pending',
      failure_count: failure_count,
    )
  end
  let(:failed_example_notification) do
    instance_double(RSpec::Core::Notifications::FailedExampleNotification,
      example: double(:example,
        metadata: {full_description: '_full_description_'},
        exception: '_exception_',
      ),
    )
  end

  it 'sends a failure notification for the first failure only' do
    expect(TerminalNotifier).to receive(:notify).with(
      "_full_description_\n_exception_",
      title: "#{Nc::FAILURE_EMOJI} #{current_dir}: Failure",
    )
    formatter.example_failed failed_example_notification

    expect(TerminalNotifier).to_not receive(:notify)
    formatter.example_failed failed_example_notification

    expect(TerminalNotifier).to_not receive(:notify)
    formatter.dump_summary summary_notification
  end


  context 'with all examples passing' do
    let(:failure_count) { 0 }

    it 'sends a success summary notification' do
      formatter.dump_summary summary_notification
    end
  end
end
