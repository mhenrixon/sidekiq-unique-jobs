# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq_unique_jobs/web"
require "rack/test"

RSpec.describe SidekiqUniqueJobs::Web do
  include Rack::Test::Methods

  def app
    Sidekiq::Web
  end

  before do
    flush_redis
  end

  let(:lock_one)   { SidekiqUniqueJobs::Lock.new(digest_one) }
  let(:lock_two)   { SidekiqUniqueJobs::Lock.new(digest_two) }
  let(:jid_one)    { "jid_one" }
  let(:jid_two)    { "jid_two" }
  let(:digest_one) { "uniquejobs:9e9b5ce5d423d3ea470977004b50ff84" }
  let(:digest_two) { "uniquejobs:24c5b03e2d49d765e5dfb2d7c51c5929" }
  let(:expected_digests) do
    [
      a_collection_including(digest_one, kind_of(Float)),
      a_collection_including(digest_two, kind_of(Float)),
    ]
  end

  it "can display digests" do
    lock_one.lock(jid_one)
    lock_two.lock(jid_two)

    get "/locks"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to match("/locks/#{digest_one}")
    expect(last_response.body).to match("/locks/#{digest_two}")
  end

  it "can paginate digests" do
    110.times do |idx|
      expect(MyUniqueJob.perform_async(1, idx)).not_to eq(nil)
    end

    get "/locks"

    expect(last_response.status).to eq(200)
  end

  it "can display digest" do
    lock_one.lock(jid_one)
    lock_two.lock(jid_two)

    get "/locks/#{digest_one}"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to match("uniquejobs:9e9b5ce5d423d3ea470977004b50ff84")
  end

  it "can delete digest" do
    lock_one.lock(jid_one)
    lock_two.lock(jid_two)

    expect(digests.entries).to match_array(expected_digests)

    get "/locks/#{digest_one}/delete"

    if last_response.redirect?
      expect(last_response.status).to eq(302)
      follow_redirect!
    end

    expect(last_request.url).to end_with("/locks")
    expect(last_response.body).not_to match("/locks/#{digest_one}")
    expect(last_response.body).to match("/locks/#{digest_two}")

    expect(digests.entries).to contain_exactly(
      a_collection_including(
        digest_two, kind_of(Float)
      ),
    )
  end

  it "can unlock a job" do
    lock_one.lock(jid_one)
    lock_one.lock(jid_two)

    get "/locks/#{digest_one}/jobs/#{jid_one}/delete"

    if last_response.redirect?
      expect(last_response.status).to eq(302)
      follow_redirect!
    end

    expect { lock_one.locked_jids }.to eventually_not include(jid_one)

    expect(last_request.url).to end_with("/locks/#{digest_one}")
    expect(last_response.body).not_to match("/locks/#{digest_one}/jobs/#{jid_one}")
    expect(last_response.body).to match("/locks/#{digest_one}/jobs/#{jid_two}")
  end

  it "can delete all digests" do
    lock_one.lock(jid_one)
    lock_two.lock(jid_two)

    expect(digests.entries).to match_array(expected_digests)

    get "/locks/delete_all"

    if last_response.redirect?
      expect(last_response.status).to eq(302)
      follow_redirect!

      expect(last_request.url).to end_with("/locks")
    end

    expect(last_response.body).not_to match("/locks/#{digest_one}")
    expect(last_response.body).not_to match("/locks/#{digest_two}")

    expect { digests.entries }.to eventually be_empty
  end
end
