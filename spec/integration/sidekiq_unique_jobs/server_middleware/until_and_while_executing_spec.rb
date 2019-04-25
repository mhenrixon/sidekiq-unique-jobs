# frozen_string_literal: true

# rubocop:disable RSpec/FilePath, RSpec/DescribeMethod
RSpec.describe SidekiqUniqueJobs::ServerMiddleware, "unique: :until_and_while_executing", redis: :redis do
  let(:server) { described_class.new }

  let(:jid_one)      { "jid one" }
  let(:jid_two)      { "jid two" }
  let(:lock_timeout) { nil }
  let(:sleepy_time)  { 0 }
  let(:worker_class) { UntilAndWhileExecutingJob }
  let(:unique)       { :until_and_while_executing }
  let(:queue)        { :another_queue }
  let(:args)         { [sleepy_time] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { "jid" => jid_one,
      "class" => worker_class.to_s,
      "queue" => queue,
      "lock" => unique,
      "args" => args,
      "lock_timeout" => lock_timeout }
  end
  let(:item_two) do
    item_one.merge("jid" => jid_two)
  end

  let(:key)     { SidekiqUniqueJobs::Key.new("uniquejobs:f07093737839f88af8593c945143574d") }
  let(:run_key) { SidekiqUniqueJobs::Key.new("uniquejobs:f07093737839f88af8593c945143574d:RUN") }

  context "when item_one is locked" do
    let(:pushed_jid) { push_item(item_one) }

    before do
      pushed_jid
    end

    specify { expect(pushed_jid).to eq(jid_one) }

    context "with a lock_timeout of 0" do
      let(:lock_timeout) { 0 }

      context "when processing takes 0 seconds" do
        let(:sleepy_time) { 0 }

        it "cannot lock item_two" do
          expect(push_item(item_two)).to eq(nil)
        end

        # TODO: Why is this all of a sudden -2?
        it "item_one can be executed by server" do
          expect(unique_keys).to match_array([key.grabbed, key.exists])
          server.call(worker_class, item_one, queue) {}
          expect(unique_keys).to match_array([key.available, run_key.available])
          expect(key.available).to expire_in(5)
          expect(run_key.available).to expire_in(5)
        end
      end
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/DescribeMethod
