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
          li do
            a(href: "/sidekiq", target: "_blank", class: "font-medium gap-1") do
              hero("server-stack", variant: :outline, class: "w-4 h-4")
              plain "Sidekiq Web"
              hero("arrow-top-right-on-square", variant: :mini, class: "w-3 h-3 opacity-50")
            end
          end
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
            li { a(href: "/sidekiq", target: "_blank") { "Sidekiq Web" } }
          end
        end
      end
    end
  end
end
