# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/web'
require 'sidekiq_unique_jobs/web'
require 'rack/test'

RSpec.describe SidekiqUniqueJobs::Web, redis: :redis do
  include Rack::Test::Methods

  def app
    Sidekiq::Web
  end

  before do
    Sidekiq.redis(&:flushdb)
  end

  let(:digest)           { 'uniquejobs:9e9b5ce5d423d3ea470977004b50ff84' }
  let(:another_digest)   { 'uniquejobs:24c5b03e2d49d765e5dfb2d7c51c5929' }
  let(:expected_digests) { [digest, another_digest] }

  it 'can display digests' do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)
    expect(MyUniqueJob.perform_async(2, 3)).not_to eq(nil)

    get '/unique_digests'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to match("/unique_digests/#{digest}")
    expect(last_response.body).to match("/unique_digests/#{another_digest}")
  end

  it 'can paginate digests' do
    110.times do |idx|
      expect(MyUniqueJob.perform_async(1, idx)).not_to eq(nil)
    end

    get '/unique_digests'
    expect(last_response.status).to eq(200)
  end

  it 'can display digest' do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)

    get "/unique_digests/#{digest}"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to match('uniquejobs:9e9b5ce5d423d3ea470977004b50ff84')
    expect(last_response.body).to match('uniquejobs:9e9b5ce5d423d3ea470977004b50ff84:EXISTS')
    expect(last_response.body).to match('uniquejobs:9e9b5ce5d423d3ea470977004b50ff84:VERSION')
    expect(last_response.body).to match('uniquejobs:9e9b5ce5d423d3ea470977004b50ff84:GRABBED')
  end

  it 'can delete a digest' do
    expect(MyUniqueJob.perform_async(1, 2)).not_to eq(nil)
    expect(MyUniqueJob.perform_async(2, 3)).not_to eq(nil)

    expect(SidekiqUniqueJobs::Digests.all).to match_array(expected_digests)

    get "/unique_digests/#{digest}/delete"
    expect(last_response.status).to eq(302)

    follow_redirect!

    expect(last_request.url).to end_with('/unique_digests')
    expect(last_response.body).not_to match("/unique_digests/#{digest}")
    expect(last_response.body).to match("/unique_digests/#{another_digest}")

    expect(SidekiqUniqueJobs::Digests.all).to match_array([another_digest])
  end
end
