# frozen_string_literal: true

RSpec.shared_examples "digest key does not exist" do
  it { expect(key.digest).not_to exist }
end

RSpec.shared_examples "queued keydoes not exist" do
  it { expect(key.queued).not_to exist }
end

RSpec.shared_examples "queued key does not exist" do
  it { expect(key.primed).not_to exist }
end

RSpec.shared_examples "unique set does not exist" do
  it { expect(key.unique_set).not_to exist }
end

RSpec.shared_examples "queued key exists with expiration" do
  it "removes the job_id from sorted set" do
    expect(unique_keys).to include(key.queued)
    expect(zrank(key.queued, jid_to_compare)).to eq(nil)
    expect(zscore(key.queued, jid_to_compare)).to eq(nil)

    if lock_ttl
      expect(key.queued).to have_ttl(lock_ttl)
    else
      expect(key.queued).to have_ttl(5)
    end
  end
end

RSpec.shared_examples "primed key exists with expiration" do
  it "removes the job_id from sorted set" do
    expect(unique_keys).to include(key.primed)
    expect(zrank(key.primed, jid_to_compare)).to eq(nil)
    expect(zscore(key.primed, jid_to_compare)).to eq(nil)

    if lock_ttl
      expect(key.primed).to have_ttl(lock_ttl)
    else
      expect(key.primed).to have_ttl(5)
    end
  end
end

RSpec.shared_examples "keys are removed by unlock" do
  it_behaves_like "digest key does not exist"
  it_behaves_like "queued keyexists with expiration"
  it_behaves_like "primed key exists with expiration"
  it_behaves_like "unique set does not exist"
end

RSpec.shared_examples "keys are removed by delete" do
  it_behaves_like "digest key does not exist"
  it_behaves_like "queued keydoes not exist"
  it_behaves_like "primed key does not exist"
  it_behaves_like "unique set does not exist"
end

RSpec.shared_examples "keys for other jobs are not removed" do
  it_behaves_like "digest key exists"
  it_behaves_like "queued keyexists"
  it_behaves_like "primed key exists"
  it_behaves_like "digest exists in unique set"
end
