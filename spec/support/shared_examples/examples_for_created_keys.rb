# frozen_string_literal: true

def jid_to_compare
  (locked_jid == "2") ? job_id : locked_jid
end

RSpec.shared_examples "digest key exists" do
  it "contains a key with without suffix" do
    expect(unique_keys).to include(key.digest)
    expect(get(key.digest)).to eq(jid_to_compare)
    expect(key.digest).to have_ttl(lock_ttl) if lock_ttl
  end
end

RSpec.shared_examples "queued key exists" do
  it "contains a key with suffix :QUEUED" do
    expect(unique_keys).to include(key.queued)
    expect(key.queued).to have_member(jid_to_compare)

    expect(key.queued).to have_ttl(lock_ttl) if lock_ttl
  end
end

RSpec.shared_examples "primed key exists" do
  it "contains a key with suffix :PRIMED" do
    expect(unique_keys).to include(key.primed)
    expect(key.primed).to have_member(jid_to_compare)

    expect(key.primed).to have_ttl(lock_ttl) if lock_ttl
  end
end

RSpec.shared_examples "locked key exists" do
  it "contains a key with suffix :PRIMED" do
    expect(unique_keys).to include(key.locked)
    expect(hexists(key.locked, jid_to_compare)).to eq(true)
    expect(hget(key.locked, jid_to_compare).to_f).to be_a(Float)

    expect(key.locked).to have_ttl(lock_ttl) if lock_ttl
  end
end

RSpec.shared_examples "digest exists in unique set" do
  it "has an entry for digest in unique set" do
    expect(key.unique_set).to include(key.digest)
  end
end

RSpec.shared_examples "lock creates keys" do
  it_behaves_like "digest key exists"
  it_behaves_like "queued key exists"
  it_behaves_like "digest exists in unique set"
end

RSpec.shared_examples "keys created by lock until_expired" do
  it_behaves_like "digest key exists"
  it_behaves_like "queued key exists"

end

RSpec.shared_examples "redis has keys created by lock.lua" do
  it_behaves_like "digest key exists"
  it_behaves_like "queued key exists"
  it_behaves_like "primed key exists"
  it_behaves_like "locked key exists"
end
