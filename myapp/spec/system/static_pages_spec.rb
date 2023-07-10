# frozen_string_literal: true

require "system_helper"

RSpec.describe "Static pages", type: :system do
  it "can browse" do
    visit "/"
    expect(page).to have_selector(".landing", text: "Welcome")
  end
end
