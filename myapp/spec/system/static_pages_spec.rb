# frozen_string_literal: true

require "system_helper"

RSpec.describe "Static pages", driver: :null do
  let(:page) { @playwright_page }

  it "can browse" do
    page.goto(root_path)
    welcome_text = page.text_content(".landing")
    expect(welcome_text).to match("Welcome")
  end
end
