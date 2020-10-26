require 'spec_helper'

describe Guard::Reek do
  subject { described_class.new options }
  let(:options) { { runner: runner, ui: ui } }
  let(:ui) { class_double('Guard::UI', info: true) }
  let(:runner) { instance_double('Guard::Reek::Runner') }

  describe '#start' do
    def start
      subject.start
    end

    it 'runs by default' do
      expect(runner).to receive(:run).with(no_args)
      start
    end

    it 'wont run when all_on_start is false' do
      options[:all_on_start] = false
      expect(runner).to_not receive(:run)
      start
    end

    it 'runs when all_on_start is true' do
      options[:all_on_start] = true
      expect(runner).to receive(:run).with(no_args)
      start
    end

    it 'raises :task_has_failed if runner throws exception' do
      allow(runner).to receive(:run).and_raise(RuntimeError)
      expect { start }.to raise_exception(UncaughtThrowError)
    end
  end

  describe '#run_all' do
    def run_all
      subject.run_all
    end

    it 'runs by default' do
      expect(runner).to receive(:run).with(no_args)
      run_all
    end

    it 'wont run when run_all is false' do
      options[:run_all] = false
      expect(runner).to_not receive(:run)
      run_all
    end

    it 'runs when all_on_start is true' do
      options[:run_all] = true
      expect(runner).to receive(:run).with(no_args)
      run_all
    end

    it 'raises :task_has_failed if runner throws exception' do
      allow(runner).to receive(:run).and_raise(RuntimeError)
      expect { run_all }.to raise_exception(UncaughtThrowError)
    end
  end

  describe '#run_on_additions' do
    def run_on_additions(paths)
      subject.run_on_additions(paths)
    end

    it 'runs by default' do
      expect(runner).to receive(:run).with(['lib/myfile.rb'])
      run_on_additions(['lib/myfile.rb'])
    end

    it 'raises :task_has_failed if runner throws exception' do
      allow(runner).to receive(:run).and_raise(RuntimeError)
      expect { run_on_additions(['lib/myfile.rb']) }.to raise_exception(UncaughtThrowError)
    end
  end

  describe '#run_on_modifications' do
    def run_on_modifications(paths)
      subject.run_on_modifications(paths)
    end

    it 'runs by default' do
      expect(runner).to receive(:run).with(['lib/myfile.rb'])
      run_on_modifications(['lib/myfile.rb'])
    end

    it 'raises :task_has_failed if runner throws exception' do
      allow(runner).to receive(:run).and_raise(RuntimeError)
      expect { run_on_modifications(['lib/myfile.rb']) }.to raise_exception(UncaughtThrowError)
    end
  end
end
