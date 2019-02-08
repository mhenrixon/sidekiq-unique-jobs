# frozen_string_literal: true

require "spec_helper"
RSpec.describe UniqueJobOnConflictReject do
  it_behaves_like "sidekiq with options" do
    let(:options) do
      {
        "lock" => :while_executing,
        "on_conflict" => :reject,
        "queue" => :customqueue,
        "retry" => true,
      }
    end
  end

  it_behaves_like "a performing worker" do
    let(:args) { ["hundred", "type" => "extremely unique", "id" => 44] }
  end
end
