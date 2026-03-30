# frozen_string_literal: true

class ApplicationLayout < ApplicationView
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::JavascriptImportmapTags
  include Phlex::Rails::Helpers::StylesheetLinkTag

  def initialize(title: "SidekiqUniqueJobs Test App")
    @title = title
  end

  def view_template(&)
    doctype

    html data: { theme: "dracula" } do
      head do
        title { @title }
        meta name: "viewport", content: "width=device-width,initial-scale=1"
        csp_meta_tag
        csrf_meta_tags

        stylesheet_link_tag("application", data_turbo_track: "reload")
        javascript_importmap_tags
      end

      body class: "min-h-screen bg-base-200" do
        render AppNavbar.new
        render_flash

        main class: "container mx-auto px-4 sm:px-6 lg:px-8 py-8 max-w-7xl" do
          yield
        end

        render Footer.new
      end
    end
  end

  private

  def render_flash
    flash.each do |type, msg|
      alert_class = case type
      when "notice", "success" then "alert-success"
      when "alert", "error" then "alert-error"
      when "warning" then "alert-warning"
      else "alert-info"
      end

      div(class: "toast toast-top toast-end z-50", data: { controller: "flash" }) do
        div(class: "alert #{alert_class} shadow-lg") do
          span { msg }
        end
      end
    end
  end
end
