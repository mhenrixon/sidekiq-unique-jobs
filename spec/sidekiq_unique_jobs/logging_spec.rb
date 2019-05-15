# frozen_string_literal: true

require "spec_helper"

RSpec.describe SidekiqUniqueJobs::Logging do
  let(:logger)  { SidekiqUniqueJobs.logger }
  let(:message) { "A log message" }
  let(:level)   { nil }
  let(:item)    { { "lock" => "until_executed", "unique_digest" => "abcdef" } }

  before do
    allow(logger).to receive(level)
  end

  include described_class

  describe "#log_debug" do
    let(:level) { :debug }

    it "delegates to logger.debug" do
      expect(log_debug(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_info" do
    let(:level) { :info }

    it "delegates to logger.info" do
      expect(log_info(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_warn" do
    let(:level) { :warn }

    it "delegates to logger.warn" do
      expect(log_warn(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_error" do
    let(:level) { :error }

    it "delegates to logger.error" do
      expect(log_error(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#log_fatal" do
    let(:level) { :fatal }

    it "delegates to logger.fatal" do
      expect(log_fatal(message)).to be_nil
      expect(logger).to have_received(level).with(message)
    end
  end

  describe "#with_configured_loggers_context" do
    let(:level) { :warn }

    context "when Sidekiq::Logging is defined" do
      before do
        if defined?(Sidekiq::Logging)
          @keep_constant = true
        else
          @keep_constant = false
          require 'time'
          require 'logger'
          require 'fcntl'

          module Sidekiq
            module Logging

              class Pretty < Logger::Formatter
                SPACE = " "

                # Provide a call() method that returns the formatted message.
                def call(severity, time, program_name, message)
                  "#{time.utc.iso8601(3)} #{::Process.pid} TID-#{Thread.current.object_id.to_s(36)}#{context} #{severity}: #{message}\n"
                end

                def context
                  c = Thread.current[:sidekiq_context]
                  " #{c.join(SPACE)}" if c && c.any?
                end
              end

              class WithoutTimestamp < Pretty
                def call(severity, time, program_name, message)
                  "#{::Process.pid} TID-#{Thread.current.object_id.to_s(36)}#{context} #{severity}: #{message}\n"
                end
              end

              def self.with_context(msg)
                Thread.current[:sidekiq_context] = []
                Thread.current[:sidekiq_context] << msg
                yield
              ensure
                Thread.current[:sidekiq_context] = {}
              end

              def self.initialize_logger(log_target = STDOUT)
                oldlogger = defined?(@logger) ? @logger : nil
                @logger = Logger.new(log_target)
                @logger.level = Logger::INFO
                @logger.formatter = ENV['DYNO'] ? WithoutTimestamp.new : Pretty.new
                oldlogger.close if oldlogger && !$TESTING # don't want to close testing's STDOUT logging
                @logger
              end

              def self.logger
                defined?(@logger) ? @logger : initialize_logger
              end

              def self.logger=(log)
                @logger = (log ? log : Logger.new(File::NULL))
              end

              # This reopens ALL logfiles in the process that have been rotated
              # using logrotate(8) (without copytruncate) or similar tools.
              # A +File+ object is considered for reopening if it is:
              #   1) opened with the O_APPEND and O_WRONLY flags
              #   2) the current open file handle does not match its original open path
              #   3) unbuffered (as far as userspace buffering goes, not O_SYNC)
              # Returns the number of files reopened
              def self.reopen_logs
                to_reopen = []
                append_flags = File::WRONLY | File::APPEND

                ObjectSpace.each_object(File) do |fp|
                  begin
                    if !fp.closed? && fp.stat.file? && fp.sync && (fp.fcntl(Fcntl::F_GETFL) & append_flags) == append_flags
                      to_reopen << fp
                    end
                  rescue IOError, Errno::EBADF
                  end
                end

                nr = 0
                to_reopen.each do |fp|
                  orig_st = begin
                    fp.stat
                  rescue IOError, Errno::EBADF
                    next
                  end

                  begin
                    b = File.stat(fp.path)
                    next if orig_st.ino == b.ino && orig_st.dev == b.dev
                  rescue Errno::ENOENT
                  end

                  begin
                    File.open(fp.path, 'a') { |tmpfp| fp.reopen(tmpfp) }
                    fp.sync = true
                    nr += 1
                  rescue IOError, Errno::EBADF
                    # not much we can do...
                  end
                end
                nr
              rescue RuntimeError => ex
                # RuntimeError: ObjectSpace is disabled; each_object will only work with Class, pass -X+O to enable
                puts "Unable to reopen logs: #{ex.message}"
              end

              def logger
                Sidekiq::Logging.logger
              end
            end
          end
        end

        allow(logger).to receive(:respond_to?).with(:with_context).and_return(false)
        allow(Sidekiq::Logging).to receive(:with_context).and_call_original
      end

      after do
        Sidekiq.send(:remove_const, "Logging") unless @keep_constant
      end

      it "sets up a logging context" do
        with_configured_loggers_context do
          log_warn("TOODELOO")
        end

        expect(logger).to have_received(:warn).with("TOODELOO")
      end
    end

    context "when logger does not support context" do
      let(:logger) { Logger.new("/dev/null") }

      before do
        allow(logger).to receive(:respond_to?).with(:with_context).and_return(false)
      end

      it "logs a warning" do
        with_configured_loggers_context { }

        expect(logger).to have_received(:warn).with(
          "Don't know how to create the logging context. Please open a feature request:" \
          " https://github.com/mhenrixon/sidekiq-unique-jobs/issues/new?template=feature_request.md"
        )
      end
    end
  end
end
