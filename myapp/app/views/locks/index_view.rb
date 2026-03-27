# frozen_string_literal: true

module Locks
  class IndexView < ApplicationView
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::LinkTo

    LOCK_TYPE_COLORS = {
      until_executed: "badge-info",
      until_executing: "badge-success",
      until_expired: "badge-warning",
      until_and_while_executing: "badge-secondary",
      while_executing: "badge-accent",
      while_enqueued: "badge-primary",
    }.freeze

    LOCK_TYPE_ICONS = {
      until_executed: "M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
      until_executing: "M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.347a1.125 1.125 0 0 1 0 1.972l-11.54 6.347a1.125 1.125 0 0 1-1.667-.986V5.653Z",
      until_expired: "M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
      until_and_while_executing: "M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182",
      while_executing: "M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z",
    }.freeze

    def initialize(jobs:, digests:, queue_stats:)
      @jobs = jobs
      @digests = digests
      @queue_stats = queue_stats
    end

    def view_template
      div(class: "space-y-8") do
        page_header
        stats_section if @queue_stats
        jobs_section
        active_locks_section
      end
    end

    private

    def page_header
      div(class: "hero bg-base-100 rounded-box shadow-sm") do
        div(class: "hero-content text-center py-8") do
          div(class: "max-w-2xl") do
            h1(class: "text-4xl font-bold") do
              plain "Lock Testing Dashboard"
            end
            p(class: "py-3 text-base-content/60") do
              plain "Test sidekiq-unique-jobs lock types, enqueue jobs, and inspect active locks in real time"
            end
            div(class: "flex gap-2 justify-center") do
              button_to "Flush All Locks", flush_locks_path,
                method: :delete,
                class: "btn btn-error btn-outline btn-sm gap-2",
                data: { turbo_confirm: "This will delete all lock digests. Continue?" } do
                svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-4 h-4") do |s|
                  s.path(
                    fill_rule: "evenodd",
                    d: "M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z",
                    clip_rule: "evenodd",
                  )
                end
                plain "Flush All Locks"
              end
            end
          end
        end
      end
    end

    def stats_section
      div(class: "grid grid-cols-2 lg:grid-cols-4 gap-4") do
        stat_card("Processed", @queue_stats.processed.to_s, "text-success", completed_icon)
        stat_card("Failed", @queue_stats.failed.to_s, "text-error", failed_icon)
        stat_card("Enqueued", @queue_stats.enqueued.to_s, "text-info", queue_icon)
        stat_card("Active Locks", @digests.size.to_s, "text-warning", lock_icon)
      end
    end

    def stat_card(title, value, color_class, icon_path)
      div(class: "stat bg-base-100 rounded-box shadow-sm place-items-center") do
        div(class: "stat-figure #{color_class}") do
          svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", class: "w-8 h-8") do |s|
            s.path(stroke_linecap: "round", stroke_linejoin: "round", d: icon_path)
          end
        end
        div(class: "stat-title") { title }
        div(class: "stat-value #{color_class} text-2xl") { value }
      end
    end

    def jobs_section
      div(class: "space-y-4") do
        div(class: "flex items-center gap-3") do
          h2(class: "text-2xl font-bold") { "Available Jobs" }
          div(class: "badge badge-neutral badge-lg") { @jobs.size.to_s }
        end

        div(class: "grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4") do
          @jobs.each do |job_name, info|
            job_card(job_name, info)
          end
        end
      end
    end

    def job_card(job_name, info)
      lock_type = info[:lock_type]
      badge_class = LOCK_TYPE_COLORS.fetch(lock_type, "badge-ghost")
      icon_path = LOCK_TYPE_ICONS.fetch(lock_type, LOCK_TYPE_ICONS[:until_executed])

      div(class: "card bg-base-100 shadow-sm hover:shadow-md transition-shadow border border-base-300/50") do
        div(class: "card-body gap-3 p-5") do
          # Header with icon and name
          div(class: "flex items-start justify-between") do
            div(class: "flex items-center gap-2") do
              div(class: "p-2 rounded-lg bg-base-200") do
                svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", class: "w-5 h-5 text-primary") do |s|
                  s.path(stroke_linecap: "round", stroke_linejoin: "round", d: icon_path)
                end
              end
              h3(class: "card-title text-base font-semibold") { job_name }
            end

            div(class: "badge #{badge_class} badge-sm font-mono") do
              plain lock_type.to_s
            end
          end

          # Description
          p(class: "text-sm text-base-content/60 leading-relaxed") { info[:description] }

          # Args display
          if info[:sample_args].any?
            div(class: "mockup-code bg-base-200 text-xs py-1 px-4") do
              pre(data: { prefix: ">" }) do
                code { info[:sample_args].inspect }
              end
            end
          end

          # Divider
          div(class: "divider my-0")

          # Actions
          div(class: "card-actions items-center justify-between") do
            link_to lock_path(job_name), class: "btn btn-ghost btn-sm gap-1" do
              svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-4 h-4") do |s|
                s.path(d: "M10 12.5a2.5 2.5 0 100-5 2.5 2.5 0 000 5z")
                s.path(fill_rule: "evenodd", d: "M.664 10.59a1.651 1.651 0 010-1.186A10.004 10.004 0 0110 3c4.257 0 7.893 2.66 9.336 6.41.147.381.146.804 0 1.186A10.004 10.004 0 0110 17c-4.257 0-7.893-2.66-9.336-6.41zM14 10a4 4 0 11-8 0 4 4 0 018 0z", clip_rule: "evenodd")
              end
              plain "Inspect"
            end

            div(class: "join") do
              [1, 3, 5].each do |count|
                enqueue_button(job_name, count)
              end
            end
          end
        end
      end
    end

    def enqueue_button(job_name, count)
      button_to enqueue_locks_path,
        params: { job_name: job_name, count: count },
        class: "btn btn-primary btn-sm join-item",
        "aria-label": "Enqueue #{job_name} x#{count}" do
        plain "x#{count}"
      end
    end

    def active_locks_section
      div(class: "space-y-4") do
        div(class: "flex items-center gap-3") do
          h2(class: "text-2xl font-bold") { "Active Locks" }
          span(class: "badge badge-lg #{@digests.any? ? 'badge-warning' : 'badge-ghost'}") do
            plain @digests.size.to_s
          end
        end

        if @digests.empty?
          div(class: "card bg-base-100 shadow-sm") do
            div(class: "card-body items-center text-center py-12") do
              svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", class: "w-16 h-16 text-base-content/20") do |s|
                s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M13.5 10.5V6.75a4.5 4.5 0 119 0v3.75M3.75 21.75h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H3.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z")
              end
              p(class: "text-base-content/40 mt-4 text-lg") { "No active locks" }
              p(class: "text-base-content/30 text-sm") { "Enqueue some jobs above to see locks appear here" }
            end
          end
        else
          div(class: "card bg-base-100 shadow-sm") do
            div(class: "overflow-x-auto") do
              table(class: "table") do
                thead do
                  tr do
                    th { "Digest" }
                    th { "Worker" }
                    th { "Lock Type" }
                    th { "Queue" }
                  end
                end

                tbody do
                  @digests.each do |entry|
                    lock_row(entry)
                  end
                end
              end
            end
          end
        end
      end
    end

    def lock_row(entry)
      info = entry[:info]
      lock_type = info["type"]&.to_sym
      badge_class = LOCK_TYPE_COLORS.fetch(lock_type, "badge-ghost")

      tr(class: "hover") do
        td do
          code(class: "text-xs font-mono text-base-content/70") do
            plain entry[:digest].to_s.truncate(50)
          end
        end
        td(class: "font-medium") { info["worker"] || "-" }
        td do
          div(class: "badge #{badge_class} badge-sm font-mono") do
            plain(info["type"] || "-")
          end
        end
        td { info["queue"] || "-" }
      end
    end

    # Icon paths
    def completed_icon = "M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
    def failed_icon = "M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z"
    def queue_icon = "M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875 0 0 1 0-3.75Z"
    def lock_icon = "M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z"
  end
end
