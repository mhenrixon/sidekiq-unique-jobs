# frozen_string_literal: true

class Navbar < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  def view_template
    div(class: "navbar bg-base-100 border-b border-base-300 sticky top-0 z-40") do
      div(class: "navbar-start") do
        link_to root_path, class: "btn btn-ghost gap-2 text-xl font-bold normal-case" do
          hero("lock-closed", variant: :solid, class: "w-6 h-6 text-primary")
          span { "SUJ" }
          span(class: "badge badge-primary badge-sm") { "test" }
        end
      end

      div(class: "navbar-center hidden lg:flex") do
        ul(class: "menu menu-horizontal gap-1") do
          li do
            link_to locks_path, class: "font-medium gap-1" do
              hero("squares-2x2", variant: :outline, class: "w-4 h-4")
              plain "Dashboard"
            end
          end

          sidekiq_dropdown
        end
      end

      div(class: "navbar-end") do
        div(class: "dropdown dropdown-end lg:hidden") do
          div(tabindex: "0", role: "button", class: "btn btn-ghost") do
            hero("bars-3", variant: :outline, class: "w-5 h-5")
          end
          ul(
            tabindex: "0",
            class: "menu menu-sm dropdown-content bg-base-100 rounded-box z-10 mt-3 w-52 p-2 shadow-lg border border-base-300",
          ) do
            li { link_to "Dashboard", locks_path }
            li do
              details do
                summary { "Sidekiq Admin" }
                ul do
                  sidekiq_nav_items
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def sidekiq_dropdown
    li do
      details do
        summary(class: "font-medium gap-1") do
          hero("server-stack", variant: :outline, class: "w-4 h-4")
          plain "Sidekiq Admin"
        end
        ul(class: "bg-base-100 rounded-box z-50 w-48 p-2 shadow-lg border border-base-300") do
          sidekiq_nav_items
        end
      end
    end
  end

  def sidekiq_nav_items
    nav_items = [
      { path: "/sidekiq", label: "Dashboard", icon: "chart-bar" },
      { path: "/sidekiq/queues", label: "Queues", icon: "queue-list" },
      { path: "/sidekiq/retries", label: "Retries", icon: "arrow-path" },
      { path: "/sidekiq/scheduled", label: "Scheduled", icon: "clock" },
      { path: "/sidekiq/dead", label: "Dead", icon: "x-circle" },
      { path: "/sidekiq/locks", label: "Locks (SUJ)", icon: "lock-closed" },
    ]

    nav_items.each do |item|
      li do
        a(href: item[:path], class: "gap-2") do
          hero(item[:icon], variant: :mini, class: "w-4 h-4")
          plain item[:label]
        end
      end
    end
  end
end
