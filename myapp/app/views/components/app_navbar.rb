# frozen_string_literal: true

# Named AppNavbar to avoid collision with DaisyUI::Navbar from Phlex::Kit
class AppNavbar < ApplicationComponent
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
    div(class: "bg-neutral text-neutral-content px-4 py-2") do
      div(class: "max-w-7xl mx-auto flex items-center justify-between flex-wrap gap-2") do
        # Logo
        link_to root_path, class: "flex items-center gap-2 font-bold text-lg hover:opacity-80" do
          hero("lock-closed", variant: :solid, class: "w-5 h-5 text-primary")
          span { "SUJ" }
          span(class: "badge badge-primary badge-xs") { "test" }
        end

        # Navigation links
        div(class: "flex items-center gap-1 flex-wrap") do
          link_to locks_path, class: "btn btn-ghost btn-sm text-neutral-content" do
            plain "Dashboard"
          end

          span(class: "opacity-30") { "|" }

          SIDEKIQ_LINKS.each do |item|
            a(href: item[:path], class: "btn btn-ghost btn-xs text-neutral-content") do
              plain item[:label]
            end
          end
        end
      end
    end
  end
end
