# frozen_string_literal: true

class Navbar < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  SIDEKIQ_LINKS = [
    { path: "/sidekiq", label: "Sidekiq" },
    { path: "/sidekiq/queues", label: "Queues" },
    { path: "/sidekiq/retries", label: "Retries" },
    { path: "/sidekiq/scheduled", label: "Scheduled" },
    { path: "/sidekiq/dead", label: "Dead" },
    { path: "/sidekiq/locks", label: "Locks" },
  ].freeze

  def view_template
    div(class: "navbar bg-base-100 border-b border-base-300 sticky top-0 z-40") do
      div(class: "navbar-start") do
        # Mobile hamburger
        div(class: "dropdown lg:hidden") do
          div(tabindex: "0", role: "button", class: "btn btn-ghost") do
            hero("bars-3", variant: :outline, class: "w-5 h-5")
          end
          ul(
            tabindex: "0",
            class: "menu menu-sm dropdown-content bg-base-100 rounded-box z-50 mt-3 w-56 p-2 shadow-lg border border-base-300",
          ) do
            li { link_to "Dashboard", locks_path, class: "font-medium" }
            li(class: "menu-title mt-2") { "Sidekiq Admin" }
            SIDEKIQ_LINKS.each do |item|
              li { a(href: item[:path]) { item[:label] } }
            end
          end
        end

        # Logo
        link_to root_path, class: "btn btn-ghost gap-2 text-xl font-bold normal-case" do
          hero("lock-closed", variant: :solid, class: "w-6 h-6 text-primary")
          span { "SUJ" }
          span(class: "badge badge-primary badge-sm") { "test" }
        end
      end

      # Desktop nav — always visible on lg+
      div(class: "navbar-center hidden lg:flex") do
        ul(class: "menu menu-horizontal gap-0") do
          li do
            link_to locks_path, class: "font-medium" do
              hero("squares-2x2", variant: :mini, class: "w-4 h-4")
              plain "Dashboard"
            end
          end

          li(class: "border-l border-base-300 ml-1 pl-1")

          SIDEKIQ_LINKS.each do |item|
            li do
              a(href: item[:path], class: "text-sm") { item[:label] }
            end
          end
        end
      end
    end
  end
end
