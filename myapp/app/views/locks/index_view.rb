# frozen_string_literal: true

module Locks
  class IndexView < ApplicationView
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::LinkTo

    LOCK_TYPE_STYLES = {
      until_executed: { badge: "badge-info", icon: "check-circle" },
      until_executing: { badge: "badge-success", icon: "play" },
      until_expired: { badge: "badge-warning", icon: "clock" },
      until_and_while_executing: { badge: "badge-secondary", icon: "arrow-path" },
      while_executing: { badge: "badge-accent", icon: "bolt" },
      while_enqueued: { badge: "badge-primary", icon: "queue-list" },
    }.freeze

    def initialize(jobs:, digests:, queue_stats:, reaper_config:)
      @jobs = jobs
      @digests = digests
      @queue_stats = queue_stats
      @reaper_config = reaper_config
    end

    def view_template
      div(class: "space-y-8") do
        page_header
        stats_section if @queue_stats
        reaper_section
        jobs_section
        active_locks_section
      end
    end

    private

    def page_header
      div(class: "hero bg-base-100 rounded-box shadow-sm") do
        div(class: "hero-content text-center py-8") do
          div(class: "max-w-2xl") do
            h1(class: "text-4xl font-bold") { "Lock Testing Dashboard" }
            p(class: "py-3 text-base-content/60") do
              plain "Test sidekiq-unique-jobs lock types, enqueue jobs, and inspect active locks in real time"
            end
            div(class: "flex gap-2 justify-center flex-wrap") do
              load_test_buttons
              button_to flush_locks_path,
                method: :delete,
                class: "btn btn-error btn-outline btn-sm gap-2",
                data: { turbo_confirm: "This will delete all lock digests. Continue?" } do
                hero("trash", variant: :mini, class: "w-4 h-4")
                plain "Flush All Locks"
              end
            end
          end
        end
      end
    end

    def load_test_buttons
      [50, 250, 500, 1_000].each do |count|
        button_to load_test_locks_path,
          params: { count: count },
          class: "btn btn-warning btn-sm gap-2" do
          hero("bolt", variant: :mini, class: "w-4 h-4")
          plain "Fire #{count} Jobs"
        end
      end
    end

    def stats_section
      div(class: "grid grid-cols-2 lg:grid-cols-4 gap-4") do
        stat_card("Processed", @queue_stats.processed.to_s, "text-success", "check-circle")
        stat_card("Failed", @queue_stats.failed.to_s, "text-error", "exclamation-triangle")
        stat_card("Enqueued", @queue_stats.enqueued.to_s, "text-info", "inbox-stack")
        stat_card("Active Locks", @digests.size.to_s, "text-warning", "lock-closed")
      end
    end

    def stat_card(title, value, color_class, icon_name)
      div(class: "stat bg-base-100 rounded-box shadow-sm place-items-center") do
        div(class: "stat-figure #{color_class}") do
          hero(icon_name, variant: :outline, class: "w-8 h-8")
        end
        div(class: "stat-title") { title }
        div(class: "stat-value #{color_class} text-2xl") { value }
      end
    end

    def reaper_section
      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body p-5") do
          div(class: "flex items-center gap-3 mb-3") do
            div(class: "p-2 rounded-lg bg-base-200") do
              hero("arrow-path", variant: :outline, class: "w-5 h-5 text-success")
            end
            h3(class: "font-semibold text-lg") { "Reaper Status" }
            if @reaper_config[:reaper] && @reaper_config[:reaper] != :none
              span(class: "badge badge-success badge-sm") { "Active" }
            else
              span(class: "badge badge-error badge-sm") { "Disabled" }
            end
          end

          div(class: "grid grid-cols-2 md:grid-cols-4 gap-4 text-sm") do
            reaper_stat("Mode", @reaper_config[:reaper].to_s)
            reaper_stat("Interval", "#{@reaper_config[:interval]}s")
            reaper_stat("Timeout", "#{@reaper_config[:timeout]}s")
            reaper_stat("Batch Size", @reaper_config[:count].to_s)
          end
        end
      end
    end

    def reaper_stat(label, value)
      div do
        div(class: "text-base-content/50 text-xs uppercase tracking-wide") { label }
        div(class: "font-mono font-semibold") { value }
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
      style = LOCK_TYPE_STYLES.fetch(lock_type, { badge: "badge-ghost", icon: "lock-closed" })

      div(class: "card bg-base-100 shadow-sm hover:shadow-md transition-shadow border border-base-300/50") do
        div(class: "card-body gap-3 p-5") do
          div(class: "flex items-start justify-between") do
            div(class: "flex items-center gap-2") do
              div(class: "p-2 rounded-lg bg-base-200") do
                hero(style[:icon], variant: :outline, class: "w-5 h-5 text-primary")
              end
              h3(class: "card-title text-base font-semibold") { job_name }
            end

            div(class: "badge #{style[:badge]} badge-sm font-mono") do
              plain lock_type.to_s
            end
          end

          p(class: "text-sm text-base-content/60 leading-relaxed") { info[:description] }

          if info[:sample_args].any?
            div(class: "mockup-code bg-base-200 text-xs py-1 px-4") do
              pre(data: { prefix: ">" }) do
                code { info[:sample_args].inspect }
              end
            end
          end

          div(class: "divider my-0")

          div(class: "card-actions items-center justify-between") do
            link_to lock_path(job_name), class: "btn btn-ghost btn-sm gap-1" do
              hero("eye", variant: :mini, class: "w-4 h-4")
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
              hero("lock-open", variant: :outline, class: "w-16 h-16 text-base-content/20")
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
      style = LOCK_TYPE_STYLES.fetch(lock_type, { badge: "badge-ghost", icon: "lock-closed" })

      tr(class: "hover") do
        td do
          code(class: "text-xs font-mono text-base-content/70") do
            plain entry[:digest].to_s.truncate(50)
          end
        end
        td(class: "font-medium") { info["worker"] || "-" }
        td do
          div(class: "badge #{style[:badge]} badge-sm font-mono") do
            plain(info["type"] || "-")
          end
        end
        td { info["queue"] || "-" }
      end
    end
  end
end
