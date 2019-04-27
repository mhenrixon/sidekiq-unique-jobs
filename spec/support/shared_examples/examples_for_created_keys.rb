# frozen_string_literal: true

def jid_to_compare
  (locked_jid == "2") ? job_id : locked_jid
end

RSpec.shared_examples "available key exists" do
  it "contains a key with suffix :AVAILABLE" do
    expect(unique_keys).to include(key.available)
    expect(lrange(key.available, -1, 1).shift).to eq(jid_to_compare) # unless lock_ttl # TODO: Refactor this
  end
end

RSpec.shared_examples "exists key exists" do
  it "contains a key with suffix :EXISTS" do
    expect(unique_keys).to include(key.exists)
    expect(get(key.exists)).to eq(jid_to_compare)
    expect(key.exists).to expire_in(lock_ttl) if lock_ttl # TODO: Refactor this
  end
end

RSpec.shared_examples "digest exists in unique set" do
  it "has an entry for digest in unique set" do
    expect(unique_digests).to include(key.digest)
  end
end

RSpec.shared_examples "keys created by other locks than until_expired" do
  it_behaves_like "available key exists"
  it_behaves_like "exists key exists"
  it_behaves_like "digest exists in unique set"
end

RSpec.shared_examples "keys created by until_expired" do
  it_behaves_like "available key exists"
  it_behaves_like "exists key exists"
  it_behaves_like "unique set does not exist"
end

RSpec.shared_examples "a lock with all keys created" do
  it_behaves_like "available key exists"
  it_behaves_like "exists key exists"
  it_behaves_like "digest exists in unique set"
end
