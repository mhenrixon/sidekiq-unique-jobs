# frozen_string_literal: true

require "capybara/rspec"

module LoginHelper
  def login(user)
    visit new_session_path

    raise "No user password" unless user.password

    within "form#new_session" do
      fill_in "session[email]", with: user.email
      fill_in "session[password]", with: user.password
      check "session[remember_me]", allow_label_click: true

      click_on "Sign in"
    end
  end
end

RSpec.configure do |config|
  config.include LoginHelper, type: :system
end
