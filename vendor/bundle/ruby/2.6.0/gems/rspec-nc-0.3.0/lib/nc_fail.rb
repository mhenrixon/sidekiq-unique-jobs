require 'nc'

class NcFail < Nc
  RSpec::Core::Formatters.register self, :dump_summary

  def dump_summary(notification)
    if notification.failure_count > 0
      super
    end
  end
end
