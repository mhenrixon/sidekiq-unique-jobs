# frozen_string_literal: true

require 'rspec/core'
require 'rspec/core/formatters/base_text_formatter'
require 'ruby-progressbar'
require 'fuubar/output'

RSpec.configuration.add_setting :fuubar_progress_bar_options,   :default => {}
RSpec.configuration.add_setting :fuubar_auto_refresh,           :default => false
RSpec.configuration.add_setting :fuubar_output_pending_results, :default => true

class Fuubar < RSpec::Core::Formatters::BaseTextFormatter
  DEFAULT_PROGRESS_BAR_OPTIONS = { :format => ' %c/%C |%w>%i| %e ' }.freeze

  RSpec::Core::Formatters.register self,
                                   :close,
                                   :dump_failures,
                                   :dump_pending,
                                   :example_failed,
                                   :example_passed,
                                   :example_pending,
                                   :message,
                                   :start

  attr_accessor :example_tick_thread,
                :example_tick_lock,
                :progress,
                :passed_count,
                :pending_count,
                :failed_count

  def initialize(*args)
    super

    self.example_tick_lock = Mutex.new
    self.progress = ProgressBar.create(
                      DEFAULT_PROGRESS_BAR_OPTIONS.
                        merge(:throttle_rate => continuous_integration? ? 1.0 : nil).
                        merge(:total     => 0,
                              :output    => output,
                              :autostart => false)
    )
  end

  def start(notification)
    progress_bar_options = DEFAULT_PROGRESS_BAR_OPTIONS.
                             merge(:throttle_rate => continuous_integration? ? 1.0 : nil).
                             merge(configuration.fuubar_progress_bar_options).
                             merge(:total     => notification.count,
                                   :output    => output,
                                   :autostart => false)

    self.progress            = ProgressBar.create(progress_bar_options)
    self.passed_count        = 0
    self.pending_count       = 0
    self.failed_count        = 0
    self.example_tick_thread = Thread.new do
                                 loop do
                                   sleep(1)

                                   if configuration.fuubar_auto_refresh
                                     example_tick(notification)
                                   end
                                 end
                               end # rubocop:disable Layout/BlockAlignment

    super

    with_current_color { progress.start }
  end

  def close(_notification)
    example_tick_thread.kill
  end

  def example_passed(_notification)
    self.passed_count += 1

    increment
  end

  def example_pending(_notification)
    self.pending_count += 1

    increment
  end

  def example_failed(notification)
    self.failed_count += 1

    progress.clear

    output.puts notification.fully_formatted(failed_count)
    output.puts

    increment
  end

  def example_tick(_notification)
    example_tick_lock.synchronize do
      refresh
    end
  end

  def message(notification)
    if progress.respond_to? :log
      progress.log(notification.message)
    else
      super
    end
  end

  def dump_failures(_notification)
    #
    # We output each failure as it happens so we don't need to output them en
    # masse at the end of the run.
    #
  end

  def dump_pending(notification)
    return unless configuration.fuubar_output_pending_results

    super
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def output
    @fuubar_output ||= Fuubar::Output.new(super, configuration.tty?)
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  private

  def increment
    with_current_color { progress.increment }
  end

  def refresh
    with_current_color { progress.refresh }
  end

  def with_current_color
    output.print "\e[#{color_code_for(current_color)}m" if color_enabled?
    yield
    output.print "\e[0m"                                if color_enabled?
  end

  def color_enabled?
    configuration.color_enabled? && !continuous_integration?
  end

  def current_color
    if failed_count > 0
      configuration.failure_color
    elsif pending_count > 0
      configuration.pending_color
    else
      configuration.success_color
    end
  end

  def color_code_for(*args)
    RSpec::Core::Formatters::ConsoleCodes.console_code_for(*args)
  end

  def configuration
    RSpec.configuration
  end

  def continuous_integration?
    @continuous_integration ||= \
      ![nil, '', 'false'].include?(ENV['CONTINUOUS_INTEGRATION'])
  end
end
