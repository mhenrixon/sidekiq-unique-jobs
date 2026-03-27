# frozen_string_literal: true

module Locks
  class IndexView < ApplicationView
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::LinkTo

    def initialize(jobs:, digests:, queue_stats:)
      @jobs = jobs
      @digests = digests
      @queue_stats = queue_stats
    end

    def view_template
      div(class: "space-y-6") do
        page_header
        stats_section if @queue_stats
        jobs_section
        active_locks_section
      end
    end

    private

    def page_header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-3xl font-bold") { "Lock Testing Dashboard" }
          p(class: "text-base-content/70 mt-1") do
            plain "Test sidekiq-unique-jobs lock types and inspect active locks"
          end
        end

        button_to "Flush All Locks", flush_locks_path,
          method: :delete,
          class: "btn btn-error btn-sm",
          data: { turbo_confirm: "Flush all lock digests?" }
      end
    end

    def stats_section
      div(class: "stats stats-horizontal shadow w-full bg-base-100") do
        stat("Processed", @queue_stats.processed.to_s)
        stat("Failed", @queue_stats.failed.to_s)
        stat("Enqueued", @queue_stats.enqueued.to_s)
        stat("Active Locks", @digests.size.to_s)
      end
    end

    def stat(title, value)
      div(class: "stat") do
        div(class: "stat-title") { title }
        div(class: "stat-value text-lg") { value }
      end
    end

    def jobs_section
      h2(class: "text-2xl font-bold mt-8 mb-4") { "Available Jobs" }

      div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
        @jobs.each do |job_name, info|
          job_card(job_name, info)
        end
      end
    end

    def job_card(job_name, info)
      div(class: "card bg-base-100 shadow-sm border border-base-300") do
        div(class: "card-body p-4") do
          h3(class: "card-title text-base") { job_name }

          div(class: "badge badge-outline badge-sm") do
            plain info[:lock_type].to_s
          end

          p(class: "text-sm text-base-content/70 mt-2") { info[:description] }

          if info[:sample_args].any?
            div(class: "mt-2") do
              code(class: "text-xs bg-base-200 px-2 py-1 rounded") do
                plain info[:sample_args].inspect
              end
            end
          end

          div(class: "card-actions justify-between items-center mt-4") do
            link_to "Details", lock_path(job_name),
              class: "btn btn-ghost btn-xs"

            div(class: "join") do
              enqueue_button(job_name, 1)
              enqueue_button(job_name, 3)
              enqueue_button(job_name, 5)
            end
          end
        end
      end
    end

    def enqueue_button(job_name, count)
      button_to enqueue_locks_path,
        params: { job_name: job_name, count: count },
        class: "btn btn-primary btn-xs join-item" do
        plain "x#{count}"
      end
    end

    def active_locks_section
      h2(class: "text-2xl font-bold mt-8 mb-4") do
        plain "Active Locks "
        span(class: "badge badge-neutral") { @digests.size.to_s }
      end

      if @digests.empty?
        div(class: "alert") do
          span { "No active locks" }
        end
      else
        div(class: "overflow-x-auto") do
          table(class: "table table-sm bg-base-100") do
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

    def lock_row(entry)
      info = entry[:info]
      tr(class: "hover") do
        td do
          code(class: "text-xs") do
            plain entry[:digest].to_s.truncate(50)
          end
        end
        td { info["worker"] || "-" }
        td do
          div(class: "badge badge-outline badge-sm") do
            plain(info["type"] || "-")
          end
        end
        td { info["queue"] || "-" }
      end
    end
  end
end
