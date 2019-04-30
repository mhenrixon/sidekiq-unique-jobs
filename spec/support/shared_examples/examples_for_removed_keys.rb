# frozen_string_literal: true

RSpec.shared_examples "digest key does not exist" do
  it { expect(key.lock_key).not_to exist }
end

RSpec.shared_examples "wait key does not exist" do
  it { expect(key.wait).not_to exist }
end

RSpec.shared_examples "work key does not exist" do
  it { expect(key.work).not_to exist }
end

RSpec.shared_examples "unique set does not exist" do
  it { expect(key.unique_set).not_to exist }
end

RSpec.shared_examples "wait key exists with expiration" do
  it "removes the job_id from sorted set" do
    expect(unique_keys).to include(key.wait)
    expect(zrank(key.wait, jid_to_compare)).to eq(nil)
    expect(zscore(key.wait, jid_to_compare)).to eq(nil)

    if lock_ttl
      expect(key.wait).to expire_in(lock_ttl)
    else
      expect(key.wait).to expire_in(5)
    end
  end
end

RSpec.shared_examples "work key exists with expiration" do
  it "removes the job_id from sorted set" do
    expect(unique_keys).to include(key.work)
    expect(zrank(key.work, jid_to_compare)).to eq(nil)
    expect(zscore(key.work, jid_to_compare)).to eq(nil)

    if lock_ttl
      expect(key.work).to expire_in(lock_ttl)
    else
      expect(key.work).to expire_in(5)
    end
  end
end

RSpec.shared_examples "keys are removed by unlock" do
  it_behaves_like "digest key does not exist"
  it_behaves_like "wait key exists with expiration"
  it_behaves_like "work key exists with expiration"
  it_behaves_like "unique set does not exist"
end

RSpec.shared_examples "keys are removed by delete" do
  it_behaves_like "digest key does not exist"
  it_behaves_like "wait key does not exist"
  it_behaves_like "work key does not exist"
  it_behaves_like "unique set does not exist"
end

RSpec.shared_examples "keys for other jobs are not removed" do
  it_behaves_like "digest key exists"
  it_behaves_like "wait key exists"
  it_behaves_like "work key exists"
  it_behaves_like "digest exists in unique set"
end
