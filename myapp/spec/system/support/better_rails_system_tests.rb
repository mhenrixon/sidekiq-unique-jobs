# frozen_string_literal: true

module BetterRailsSystemTests
  # Use our `Capybara.save_path` to store screenshots with other capybara artifacts
  # (Rails screenshots path is not configurable https://github.com/rails/rails/blob/49baf092439fc74fc3377b12e3334c3dd9d0752f/actionpack/lib/action_dispatch/system_testing/test_helpers/screenshot_helper.rb#L79)
  def absolute_image_path
    Rails.root.join("#{Capybara.save_path}/screenshots/#{image_name}.png")
  end

  # Use relative path in screenshot message to make it clickable in VS Code when running in Docker
  def image_path
    absolute_image_path.relative_path_from(Rails.root).to_s
  end

  # Convert dom_id to selector
  def dom_id(*args)
    "##{super}"
  end

  def flash
    find_by_id("app-flash")
  end

  def fill_in_trix_editor(id, with:)
    find(:xpath, "//trix-editor[@input='#{id}']").click.set(with)
  end

  def find_trix_editor(id)
    find(:xpath, "//*[@id='#{id}']", visible: false)
  end

  def wait_for_turbo(timeout = nil)
    return unless has_css?(".turbo-progress-bar", visible: true, wait: 0.25.seconds)

    has_no_css?(".turbo-progress-bar", wait: timeout.presence || 5.seconds)
  end

  def wait_for_turbo_frame(selector = "turbo-frame", timeout: nil)
    return unless has_selector?("#{selector}[busy]", visible: true, wait: 0.25.seconds)

    has_no_selector?("#{selector}[busy]", wait: timeout.presence || 5.seconds)
  end
end

RSpec.configure do |config|
  # Add #dom_id support
  config.include ActionView::RecordIdentifier, type: :system
  config.include BetterRailsSystemTests, type: :system

  # Make urls in mailers contain the correct server host
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host

    ex.run

    Rails.application.default_url_options[:host] = was_host
  end

  # Make sure this hook runs before others
  config.prepend_before(:each, type: :system) do
    # Use JS driver always
    driven_by Capybara.javascript_driver
  end
end
