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

  let(:digest)           { "uniquejobs:9e9b5ce5d423d3ea470977004b50ff84" }
  let(:another_digest)   { "uniquejobs:24c5b03e2d49d765e5dfb2d7c51c5929" }
  let(:expected_digests) do
    [
      a_collection_including(digest, kind_of(Float)),
      a_collection_including(another_digest, kind_of(Float)),
    ]
  end

  it "can display digests" do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)
    expect(MyUniqueJob.perform_async(2, 3)).not_to eq(nil)

    get "/unique_digests"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to match("/unique_digests/#{digest}")
    expect(last_response.body).to match("/unique_digests/#{another_digest}")
  end

  it "can paginate digests" do
    110.times do |idx|
      expect(MyUniqueJob.perform_async(1, idx)).not_to eq(nil)
    end

    get "/unique_digests"
    expect(last_response.status).to eq(200)
  end

  it "can display digest" do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)

    get "/unique_digests/#{digest}"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to match("uniquejobs:9e9b5ce5d423d3ea470977004b50ff84")
  end

  it "can delete a digest" do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)
    expect(MyUniqueJob.perform_async(2, 3)).not_to eq(nil)

    expect(SidekiqUniqueJobs::Redis::Digests.new.entries).to match_array(expected_digests)

    get "/unique_digests/#{digest}/delete"
    expect(last_response.status).to eq(302)

    follow_redirect!

    expect(last_request.url).to end_with("/unique_digests")
    expect(last_response.body).not_to match("/unique_digests/#{digest}")
    expect(last_response.body).to match("/unique_digests/#{another_digest}")

    expect(SidekiqUniqueJobs::Redis::Digests.new.entries).to contain_exactly(
      a_collection_including(
        another_digest, kind_of(Float)
      ),
    )
  end

  it "can delete all digests" do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)
    expect(MyUniqueJob.perform_async(2, 3)).not_to eq(nil)

    expect(SidekiqUniqueJobs::Redis::Digests.new.entries).to match_array(expected_digests)

    get "/unique_digests/delete_all"
    expect(last_response.status).to eq(302)

    follow_redirect!

    expect(last_request.url).to end_with("/unique_digests")
    expect(last_response.body).not_to match("/unique_digests/#{digest}")
    expect(last_response.body).not_to match("/unique_digests/#{another_digest}")

    expect(SidekiqUniqueJobs::Redis::Digests.new.entries).to be_empty
  end
end
