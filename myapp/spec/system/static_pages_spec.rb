# frozen_string_literal: true

require "system_helper"

RSpec.describe "Lock Testing Dashboard", type: :system do
  it "can browse the dashboard" do
    visit "/"
    expect(page).to have_content("Lock Testing Dashboard")
  end
end
