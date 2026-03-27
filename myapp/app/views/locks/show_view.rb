# frozen_string_literal: true

module Locks
  class ShowView < ApplicationView
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::LinkTo

    def initialize(job_name:, job_info:, lock_digests:)
      @job_name = job_name
      @job_info = job_info
      @lock_digests = lock_digests
    end

    def view_template
      div(class: "space-y-6") do
        breadcrumbs
        job_header
        job_config_card
        enqueue_section
        lock_details_section
      end
    end

    private

    def breadcrumbs
      div(class: "breadcrumbs text-sm") do
        ul do
          li { link_to "Dashboard", locks_path }
          li { @job_name }
        end
      end
    end

    def job_header
      div(class: "flex items-center gap-4") do
        h1(class: "text-3xl font-bold") { @job_name }
        div(class: "badge badge-primary badge-lg") do
          plain @job_info[:lock_type].to_s
        end
      end

      p(class: "text-base-content/70 mt-2") { @job_info[:description] }
    end

    def job_config_card
      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          h2(class: "card-title") { "Configuration" }

          div(class: "overflow-x-auto") do
            table(class: "table table-sm") do
              tbody do
                job_class = @job_name.safe_constantize
                if job_class
                  opts = job_class.sidekiq_options_hash || {}
                  opts.each do |key, value|
                    tr do
                      th(class: "font-mono text-xs") { key }
                      td do
                        code(class: "text-xs") { value.inspect }
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    def enqueue_section
      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          h2(class: "card-title") { "Enqueue" }
          p(class: "text-sm text-base-content/70 mb-4") do
            plain "Enqueue this job to test lock behavior"
          end

          div(class: "flex gap-2 flex-wrap") do
            [1, 2, 3, 5, 10].each do |count|
              button_to enqueue_locks_path,
                params: { job_name: @job_name, count: count },
                class: "btn btn-primary btn-sm" do
                plain "Enqueue x#{count}"
              end
            end
          end
        end
      end
    end

    def lock_details_section
      h2(class: "text-2xl font-bold mt-4") do
        plain "Lock State "
        span(class: "badge badge-neutral") { @lock_digests.size.to_s }
      end

      if @lock_digests.empty?
        div(class: "alert mt-4") do
          span { "No active locks for #{@job_name}" }
        end
      else
        @lock_digests.each do |entry|
          lock_detail_card(entry)
        end
      end
    end

    def lock_detail_card(entry)
      state = entry[:state] || {}
      info = entry[:info] || {}

      div(class: "card bg-base-100 shadow-sm mt-4") do
        div(class: "card-body") do
          h3(class: "font-mono text-sm break-all") { entry[:digest].to_s }

          div(class: "grid grid-cols-2 md:grid-cols-4 gap-4 mt-4") do
            state_stat("Queued", state[:queued].to_s, "badge-info")
            state_stat("Primed", state[:primed].to_s, "badge-warning")
            state_stat("Locked", (state[:locked] || {}).size.to_s, "badge-success")
            state_stat("PTTL", format_pttl(state[:pttl]), "badge-neutral")
          end

          if (locked = state[:locked]) && locked.any?
            div(class: "mt-4") do
              h4(class: "font-semibold text-sm mb-2") { "Locked JIDs" }
              div(class: "flex flex-wrap gap-2") do
                locked.each do |jid, val|
                  div(class: "badge badge-success badge-outline gap-1") do
                    code(class: "text-xs") { jid }
                    span(class: "text-xs opacity-60") { "(#{val})" }
                  end
                end
              end
            end
          end

          if info.any?
            div(class: "collapse collapse-arrow bg-base-200 mt-4") do
              input(type: "checkbox", class: "peer")
              div(class: "collapse-title text-sm font-medium") { "Lock Info" }
              div(class: "collapse-content") do
                pre(class: "text-xs overflow-x-auto") do
                  code { JSON.pretty_generate(info) }
                end
              end
            end
          end
        end
      end
    end

    def state_stat(label, value, badge_class)
      div(class: "text-center") do
        div(class: "text-xs text-base-content/60 mb-1") { label }
        div(class: "badge #{badge_class}") { value }
      end
    end

    def format_pttl(pttl)
      return "no expiry" if pttl.nil? || pttl.to_i == -1
      return "expired" if pttl.to_i == -2

      seconds = pttl.to_i / 1000.0
      if seconds > 3600
        "#{(seconds / 3600).round(1)}h"
      elsif seconds > 60
        "#{(seconds / 60).round(1)}m"
      else
        "#{seconds.round(1)}s"
      end
    end
  end
end
