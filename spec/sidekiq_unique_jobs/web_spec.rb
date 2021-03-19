# frozen_string_literal: true

require "sidekiq_unique_jobs/web"
require "rack/test"
require "rspec-html-matchers"

RSpec.describe SidekiqUniqueJobs::Web do
  include Rack::Test::Methods
  include RSpecHtmlMatchers

  def app
    @app ||= Rack::Builder.new do
      use Rack::Session::Cookie,
          key: "rack.session",
          domain: "foo.com",
          path: "/",
          expire_after: 2_592_000,
          secret: "change_me",
          old_secret: "also_change_me"

      run Sidekiq::Web
    end
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
  let(:lock_type)  { :until_executed }
  let(:changelog)  { SidekiqUniqueJobs::Changelog.new }
  let(:digests)    { SidekiqUniqueJobs::Digests.new }

  let(:lock_info) do
    { type: lock_type }
  end

  let(:expected_digests) do
    [
      a_collection_including(digest_one, kind_of(Float)),
      a_collection_including(digest_two, kind_of(Float)),
    ]
  end

  it "can paginate changelogs", sidekiq_ver: ">= 6.0" do
    Array.new(190) do |idx|
      expect(MyUniqueJob.perform_async(1, idx)).not_to eq(nil)
    end

    get "/changelogs?filter=*&count=100"
    _size, next_cursor, changelogs = changelog.page(cursor: 0, page_size: 100, pattern: "*")

    expect(last_response).to be_ok
    expect(last_response.body).to have_tag("div", with: { class: "table_container" }) do
      with_tag("tr.changelog-row", count: changelogs.size)
    end

    get "/changelogs?filter=*&cursor=#{next_cursor}&prev_cursor=0&count=100"

    expect(last_response).to be_ok
    expect(last_response.body).to have_tag("div", with: { class: "table_container" }) do
      _size, _next_cursor, changelogs = changelog.page(cursor: next_cursor, page_size: 100, pattern: "*")
      with_tag("tr.changelog-row", count: changelogs.size)
    end
  end

  it "can display changelog" do
    lock_one.lock(jid_one, lock_info)
    lock_two.lock(jid_two, lock_info)

    get "/changelogs"

    expect(last_response).to be_ok
  end

  it "can display digests" do
    lock_one.lock(jid_one, lock_info)
    lock_two.lock(jid_two, lock_info)

    get "/locks"

    expect(last_response).to be_ok
    expect(last_response.body).to match("/locks/#{digest_one}")
    expect(last_response.body).to match("/locks/#{digest_two}")
  end

  it "can paginate digests", sidekiq_ver: ">= 6.0" do
    Array.new(190) do |idx|
      expect(MyUniqueJob.perform_async(1, idx)).not_to eq(nil)
    end

    get "/locks?filter=*&count=100"
    _size, next_cursor, locks = digests.page(cursor: 0, page_size: 100, pattern: "*")

    expect(last_response).to be_ok
    expect(last_response.body).to have_tag("div", with: { class: "table_container" }) do
      with_tag("tr.lock-row", count: locks.size)
    end

    _size, next_cursor, _locks = digests.page(cursor: 0, page_size: 100, pattern: "*")
    get "/locks?filter=*&cursor=#{next_cursor}&prev_cursor=0&count=100"

    expect(last_response).to be_ok
    expect(last_response.body).to have_tag("div", with: { class: "table_container" }) do
      _size, _next_cursor, locks = digests.page(cursor: next_cursor, page_size: 100, pattern: "*")
      with_tag("tr.lock-row", count: locks.size)
    end
  end

  it "can display digest" do
    lock_one.lock(jid_one, lock_info)
    lock_two.lock(jid_two, lock_info)

    get "/locks/#{digest_one}"

    expect(last_response).to be_ok
    expect(last_response.body).to match("uniquejobs:9e9b5ce5d423d3ea470977004b50ff84")
  end

  it "can delete digest" do
    lock_one.lock(jid_one, lock_info)
    lock_two.lock(jid_two, lock_info)

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
    lock_one.lock(jid_one, lock_info)
    lock_one.lock(jid_two, lock_info)

    get "/locks/#{digest_one}/jobs/#{jid_one}/delete"

    if last_response.redirect?
      expect(last_response.status).to eq(302)
      follow_redirect!
    end

    expect(lock_one.locked_jids).not_to include(jid_one)

    expect(last_request.url).to end_with("/locks/#{digest_one}")
    expect(last_response.body).not_to match("/locks/#{digest_one}/jobs/#{jid_one}")
    expect(last_response.body).to match("/locks/#{digest_one}/jobs/#{jid_two}")
  end

  it "can delete all digests" do
    lock_one.lock(jid_one, lock_info)
    lock_two.lock(jid_two, lock_info)

    expect(digests.entries).to match_array(expected_digests)

    get "/locks/delete_all"

    if last_response.redirect?
      expect(last_response.status).to eq(302)
      follow_redirect!

      expect(last_request.url).to end_with("/locks")
    end

    expect(last_response.body).not_to match("/locks/#{digest_one}")
    expect(last_response.body).not_to match("/locks/#{digest_two}")

    expect(digests.entries).to be_empty
  end
end
