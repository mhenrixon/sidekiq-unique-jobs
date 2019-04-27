# frozen_string_literal: true

RSpec.shared_examples "available key does not exist" do
  it { expect(key.available).not_to exist }
end

RSpec.shared_examples "exists key does not exist" do
  it { expect(key.exists).not_to exist }
end

RSpec.shared_examples "grabbed key does not exist" do
  it { expect(key.grabbed).not_to exist }
end

RSpec.shared_examples "version key does not exist" do
  it { expect(key.version).not_to exist }
end

RSpec.shared_examples "unique set does not exist" do
  it { expect(key.unique_set).not_to exist }
end

RSpec.shared_examples "uniquejobs hash does not exist" do
  it { expect("uniquejobs").not_to exist }
end

RSpec.shared_examples "keys are removed by unlock" do
  it_behaves_like "available key does not exist"
  it_behaves_like "grabbed key does not exist"
  it_behaves_like "version key does not exist"
  it_behaves_like "exists key does not exist"
  it_behaves_like "unique set does not exist"
  it_behaves_like "uniquejobs hash does not exist"
end

RSpec.shared_examples "keys are removed by delete" do
  it_behaves_like "available key does not exist"
  it_behaves_like "grabbed key does not exist"
  it_behaves_like "version key does not exist"
  it_behaves_like "exists key does not exist"
  it_behaves_like "unique set does not exist"
  it_behaves_like "uniquejobs hash does not exist"
end

RSpec.shared_examples "keys for other jobs are not removed" do
  it_behaves_like "available key exists"
  it_behaves_like "exists key exists"
  it_behaves_like "digest exists in unique set"
end
