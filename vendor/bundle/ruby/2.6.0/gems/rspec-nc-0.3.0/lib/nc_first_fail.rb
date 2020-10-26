require 'nc'

class NcFirstFail < Nc
  RSpec::Core::Formatters.register self, :example_failed

  def example_failed(notification)
    example = notification.example
    body = "#{example.metadata[:full_description]}\n#{example.exception}"
    title = "#{FAILURE_EMOJI} #{directory_name}: Failure"
    unless @failed
      TerminalNotifier.notify body, title: title
    end
    @failed = true
  end

  def dump_summary(notification)
    if notification.failure_count == 0
      super
    end
  end
end
