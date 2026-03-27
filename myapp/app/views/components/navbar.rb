# frozen_string_literal: true

class Navbar < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  def view_template
    div(class: "navbar bg-base-100 shadow-sm") do
      div(class: "flex-1") do
        link_to root_path, class: "btn btn-ghost text-xl" do
          plain "SUJ Test"
        end
      end

      div(class: "flex-none") do
        ul(class: "menu menu-horizontal px-1 gap-1") do
          li { link_to "Locks", locks_path, class: "btn btn-ghost btn-sm" }
          li do
            a(href: "/sidekiq", target: "_blank", class: "btn btn-ghost btn-sm") do
              plain "Sidekiq Web"
            end
          end
        end
      end
    end
  end
end
