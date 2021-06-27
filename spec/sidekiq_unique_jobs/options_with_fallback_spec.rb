# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::OptionsWithFallback do
  let(:options_with_fallback) { class_with_options.new(item, options, worker_class) }
  let(:options)               { nil }
  let(:worker_class)          { "UntilExecutedJob" }
  let(:queue)                 { "default" }
  let(:jid)                   { "maaaahjid" }
  let(:unique)                { :until_executed }
  let(:args)                  { [1] }
  let(:item) do
    {
      "jid" => jid,
      "queue" => queue,
      "class" => worker_class,
      "lock" => unique,
      "args" => args,
    }
  end

  let(:class_with_options) do
    Class.new do
      include SidekiqUniqueJobs::OptionsWithFallback

      attr_reader :item, :worker_class

      def initialize(item, options, worker_class = nil)
        @item         = item
        @options      = options
        @worker_class = worker_class
      end
    end
  end

  describe "#unique_enabled?" do
    subject { options_with_fallback.unique_enabled? }

    let(:options) { {} }
    let(:item)    { {} }

    it { is_expected.to eq(nil) }

    context 'when options["lock"] is present' do
      let(:options) { { "lock" => "while_executing" } }
      let(:item)    { { "lock" => "until_executed" } }

      it { is_expected.to eq("while_executing") }

      context "when SidekiqUniqueJobs.config.enabled = false" do
        around do |example|
          SidekiqUniqueJobs.disable!(&example)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when item["lock"] is present' do
      let(:item) { { "lock" => "until_executed" } }

      it { is_expected.to eq("until_executed") }

      context "when SidekiqUniqueJobs.config.enabled = false" do
        around do |example|
          SidekiqUniqueJobs.disable!(&example)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe "#unique_disabled?" do
    subject { options_with_fallback.unique_disabled? }

    let(:options) { {} }
    let(:item)    { {} }

    it { is_expected.to be_truthy }

    context 'when options["lock"] is present' do
      let(:options) { { "lock" => "while_executing" } }
      let(:item)    { { "lock" => "until_executed" } }

      it { is_expected.to be_falsey }
    end

    context 'when item["lock"] is present' do
      let(:options) { {} }
      let(:item)    { { "lock" => "until_executed" } }

      it { is_expected.to be_falsey }
    end
  end

  describe "#lock_instance" do
    subject(:lock) { options_with_fallback.lock_instance }

    context 'when item["lock"] is present' do
      let(:unique) { :until_executed }

      it { is_expected.to be_a(SidekiqUniqueJobs::Lock::UntilExecuted) }

      context 'when options["lock"] is present' do
        let(:options) { { "lock" => :while_executing } }

        it { is_expected.to be_a(SidekiqUniqueJobs::Lock::WhileExecuting) }
      end
    end
  end

  describe "#lock_class" do
    subject(:lock_class) { options_with_fallback.lock_class }

    context 'when item["lock"] is present' do
      let(:item) { { "lock" => :until_executed } }

      it { is_expected.to eq(SidekiqUniqueJobs::Lock::UntilExecuted) }

      context 'when options["lock"] is present' do
        let(:options) { { "lock" => :while_executing } }

        it { is_expected.to eq(SidekiqUniqueJobs::Lock::WhileExecuting) }
      end
    end

    context "without matching class in LOCKS" do
      let(:item) { { "lock" => :until_unknown } }

      it do
        expect { lock_class }
          .to raise_error(SidekiqUniqueJobs::UnknownLock,
                          "No implementation for `lock: :until_unknown`")
      end
    end
  end

  describe "#lock_type" do
    subject { options_with_fallback.lock_type }

    context 'when options["lock"] is while_executing' do
      let(:options) { { "lock" => "while_executing" } }
      let(:item)    { { "lock" => "until_executed" } }

      it { is_expected.to eq("while_executing") }
    end

    context 'when item["lock"] is until_executed' do
      let(:options) { {} }
      let(:item)    { { "lock" => "until_executed" } }

      it { is_expected.to eq("until_executed") }
    end
  end

  describe "#options" do
    subject(:class_options) { options_with_fallback.options }

    context "when worker_class respond_to get_sidekiq_options" do
      let(:worker_class) { SimpleWorker }

      it { is_expected.to eq(SimpleWorker.get_sidekiq_options) }
    end

    context "when default_worker_options has been configured" do
      let(:worker_class)           { PlainClass }
      let(:default_worker_options) { { "lock" => :while_executing } }

      it do
        Sidekiq.use_options(default_worker_options) do
          expect(class_options).to include(default_worker_options)
        end
      end
    end
  end
end
