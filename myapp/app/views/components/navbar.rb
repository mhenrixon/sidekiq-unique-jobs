# frozen_string_literal: true

class Navbar < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  def view_template
    div(class: "navbar bg-base-100 border-b border-base-300 sticky top-0 z-40") do
      div(class: "navbar-start") do
        link_to root_path, class: "btn btn-ghost gap-2 text-xl font-bold normal-case" do
          # Lock icon
          svg(
            xmlns: "http://www.w3.org/2000/svg",
            viewBox: "0 0 24 24",
            fill: "currentColor",
            class: "w-6 h-6 text-primary",
          ) do |s|
            s.path(
              fill_rule: "evenodd",
              d: "M12 1.5a5.25 5.25 0 00-5.25 5.25v3a3 3 0 00-3 3v6.75a3 3 0 003 3h10.5a3 3 0 003-3v-6.75a3 3 0 00-3-3v-3c0-2.9-2.35-5.25-5.25-5.25zm3.75 8.25v-3a3.75 3.75 0 10-7.5 0v3h7.5z",
              clip_rule: "evenodd",
            )
          end
          span { "SUJ" }
          span(class: "badge badge-primary badge-sm") { "test" }
        end
      end

      div(class: "navbar-center hidden lg:flex") do
        ul(class: "menu menu-horizontal gap-1") do
          li do
            link_to locks_path, class: "font-medium" do
              plain "Dashboard"
            end
          end
          li do
            a(href: "/sidekiq", target: "_blank", class: "font-medium") do
              plain "Sidekiq Web"
              # External link icon
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 20 20",
                fill: "currentColor",
                class: "w-3.5 h-3.5 opacity-50",
              ) do |s|
                s.path(
                  fill_rule: "evenodd",
                  d: "M4.25 5.5a.75.75 0 00-.75.75v8.5c0 .414.336.75.75.75h8.5a.75.75 0 00.75-.75v-4a.75.75 0 011.5 0v4A2.25 2.25 0 0112.75 17h-8.5A2.25 2.25 0 012 14.75v-8.5A2.25 2.25 0 014.25 4h5a.75.75 0 010 1.5h-5zm4.943-.25l6.057-.057a.75.75 0 01.75.75v6.057a.75.75 0 01-1.5 0V7.56l-4.72 4.72a.75.75 0 01-1.06-1.06l4.72-4.72H9.193a.75.75 0 010-1.5z",
                  clip_rule: "evenodd",
                )
              end
            end
          end
        end
      end

      div(class: "navbar-end") do
        div(class: "dropdown dropdown-end lg:hidden") do
          div(tabindex: "0", role: "button", class: "btn btn-ghost") do
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              fill: "none",
              viewBox: "0 0 24 24",
              stroke: "currentColor",
              class: "w-5 h-5",
            ) do |s|
              s.path(
                stroke_linecap: "round",
                stroke_linejoin: "round",
                stroke_width: "2",
                d: "M4 6h16M4 12h16M4 18h16",
              )
            end
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
