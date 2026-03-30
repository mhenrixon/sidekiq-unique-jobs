# frozen_string_literal: true

class Navbar < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  SIDEKIQ_LINKS = [
    { path: "/sidekiq", label: "Sidekiq", icon: "server-stack" },
    { path: "/sidekiq/queues", label: "Queues", icon: "queue-list" },
    { path: "/sidekiq/retries", label: "Retries", icon: "arrow-path" },
    { path: "/sidekiq/scheduled", label: "Scheduled", icon: "clock" },
    { path: "/sidekiq/dead", label: "Dead", icon: "x-circle" },
    { path: "/sidekiq/locks", label: "Locks", icon: "lock-closed" },
  ].freeze

  def view_template
    nav(class: "bg-base-100 border-b border-base-300 px-4 py-3") do
      div(class: "max-w-7xl mx-auto flex items-center justify-between flex-wrap gap-3") do
        # Logo
        link_to root_path, class: "flex items-center gap-2 text-xl font-bold hover:opacity-80" do
          hero("lock-closed", variant: :solid, class: "w-6 h-6 text-primary")
          span { "SUJ" }
          span(class: "badge badge-primary badge-sm") { "test" }
        end

        # Navigation links
        div(class: "flex items-center gap-1 flex-wrap") do
          link_to locks_path, class: "btn btn-ghost btn-sm gap-1" do
            hero("squares-2x2", variant: :mini, class: "w-4 h-4")
            plain "Dashboard"
          end

          div(class: "divider divider-horizontal mx-0")

          SIDEKIQ_LINKS.each do |item|
            a(href: item[:path], class: "btn btn-ghost btn-sm btn-xs gap-1") do
              hero(item[:icon], variant: :mini, class: "w-3.5 h-3.5 opacity-60")
              plain item[:label]
            end
          end
        end
      end
    end
  end
end
