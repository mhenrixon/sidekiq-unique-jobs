# frozen_string_literal: true

def jid_to_compare
  (locked_jid == "2") ? job_id : locked_jid
end

RSpec.shared_examples "digest key exists" do
  it "contains a key with without suffix" do
    expect(unique_keys).to include(key.lock_key)
    expect(get(key.lock_key)).to eq(jid_to_compare)
    expect(key.lock_key).to expire_in(lock_ttl) if lock_ttl
  end
end

RSpec.shared_examples "wait key exists" do
  it "contains a key with suffix :WAIT" do
    expect(unique_keys).to include(key.wait)
    expect(zrank(key.wait, jid_to_compare)).to eq(1)
    expect(zscore(key.wait, jid_to_compare)).to be_a(Float)

    if lock_ttl
      expect(key.wait).to expire_in(lock_ttl)
    else
      expect(key.wait).to expire_in(5)
    end
  end
end

RSpec.shared_examples "work key exists" do
  it "contains a key with suffix :WORK" do
    expect(unique_keys).to include(key.work)
    expect(zrank(key.work, jid_to_compare)).to eq(1)
    expect(zscore(key.work, jid_to_compare)).to be_a(Float)

    if lock_ttl
      expect(key.work).to expire_in(lock_ttl)
    else
      expect(key.work).to expire_in(5)
    end
  end
end

RSpec.shared_examples "digest exists in unique set" do
  it "has an entry for digest in unique set" do
    expect(key.unique_set).to include(key.lock_key)
  end
end

RSpec.shared_examples "lock creates keys" do
  it_behaves_like "digest key exists"
  it_behaves_like "wait key exists"
  it_behaves_like "digest exists in unique set"
end

RSpec.shared_examples "keys created by lock until_expired" do
  it_behaves_like "digest key exists"
  it_behaves_like "wait key exists"
  it_behaves_like "unique set does not exist"
end

RSpec.shared_examples "redis has keys created by lock.lua" do
  it_behaves_like "digest key exists"
  it_behaves_like "wait key exists"
  it_behaves_like "work key exists"
  it_behaves_like "digest exists in unique set"
end
