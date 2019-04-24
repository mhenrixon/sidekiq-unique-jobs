# frozen_string_literal: true
RSpec.shared_examples "adds available key" do
  it "creates a key with suffix :AVAILABLE" do
    expect(unique_keys).to include(key.available)
    expect(lrange(key.available, -1, 1).shift).to eq(job_id) unless lock_ttl # TODO: Refactor this
  end
end

RSpec.shared_examples "adds exists key" do
  it "creates a key with suffix :EXISTS" do
    expect(unique_keys).to include(key.exists)
    expect(get(key.exists)).to eq(job_id)
    expect(ttl(key.exists)).to eq(lock_ttl) if lock_ttl # TODO: Refactor this
  end
end

RSpec.shared_examples "adds grabbed key" do
  it "creates a key with suffix :GRABBED" do
    expect(unique_keys).to include(key.grabbed)
    expect(hget(key.grabbed, job_id)).to resemble_date
    expect(ttl(key.grabbed)).to eq(lock_ttl) if lock_ttl # TODO: Refactor this
  end
end

RSpec.shared_examples "adds digest to unique set" do
  it "adds digest to unique set" do
    expect(unique_digests).to include(key.digest)
    expect(ttl(key.grabbed)).to eq(lock_ttl) if lock_ttl # TODO: Refactor this
  end
end

RSpec.shared_examples "keys created by lock" do
  it_behaves_like "adds available key"
  it_behaves_like "adds exists key"
  it_behaves_like "adds digest to unique set"
end

RSpec.shared_examples "keys created by lock" do
  it_behaves_like "adds available key"
  it_behaves_like "adds exists key"
  it_behaves_like "adds digest to unique set"
end

RSpec.shared_examples "a lock with all keys created" do
  it_behaves_like "adds available key"
  it_behaves_like "adds exists key"
  it_behaves_like "adds grabbed key"
  it_behaves_like "adds digest to unique set"
end
