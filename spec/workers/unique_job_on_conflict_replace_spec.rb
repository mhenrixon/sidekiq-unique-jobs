# frozen_string_literal: true

RSpec.describe UniqueJobOnConflictReplace do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "lock" => :until_executing,
        "on_conflict" => :replace,
        "queue" => :customqueue,
        "retry" => true,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { ["hundred", { "type" => "extremely unique", "id" => 44 }] }
  end
end
