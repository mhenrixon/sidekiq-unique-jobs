# frozen_string_literal: true

RSpec.shared_examples "a lock with all keys created" do
  it "creates a key with suffix :GRABBED" do
    expect(unique_keys).to include(key.grabbed)
    expect(hget(key.grabbed, job_id)).to resemble_date
  end

  it "creates a key with suffix :EXISTS" do
    expect(unique_keys).to include(key.exists)
    expect(get_key(key.exists)).to eq(job_id)
  end

  it "creates a key with suffix :AVAILABLE" do
    expect(unique_keys).to include(key.available)
    expect(lrange(key.available, -1, 1).shift).to eq(job_id)
  end

  it "adds digest to unique set" do
    expect(unique_digests).to include(key.digest)
  end
end
