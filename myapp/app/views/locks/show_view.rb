# frozen_string_literal: true

module Locks
  class ShowView < ApplicationView
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::LinkTo

    LOCK_TYPE_COLORS = IndexView::LOCK_TYPE_COLORS

    def initialize(job_name:, job_info:, lock_digests:)
      @job_name = job_name
      @job_info = job_info
      @lock_digests = lock_digests
    end

    def view_template
      div(class: "space-y-6") do
        breadcrumbs
        job_header
        enqueue_section
        job_config_card
        lock_details_section
      end
    end

    private

    def breadcrumbs
      div(class: "breadcrumbs text-sm") do
        ul do
          li do
            link_to locks_path, class: "gap-1 inline-flex items-center" do
              svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 20 20", fill: "currentColor", class: "w-4 h-4") do |s|
                s.path(fill_rule: "evenodd", d: "M9.293 2.293a1 1 0 011.414 0l7 7A1 1 0 0117 11h-1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-3a1 1 0 00-1-1H9a1 1 0 00-1 1v3a1 1 0 01-1 1H5a1 1 0 01-1-1v-6H3a1 1 0 01-.707-1.707l7-7z", clip_rule: "evenodd")
              end
              plain "Dashboard"
            end
          end
          li(class: "font-medium") { @job_name }
        end
      end
    end

    def job_header
      lock_type = @job_info[:lock_type]
      badge_class = LOCK_TYPE_COLORS.fetch(lock_type, "badge-ghost")

      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          div(class: "flex flex-col sm:flex-row sm:items-center gap-3") do
            h1(class: "text-3xl font-bold") { @job_name }
            div(class: "badge #{badge_class} badge-lg font-mono") do
              plain lock_type.to_s
            end
          end
          p(class: "text-base-content/60 mt-1") { @job_info[:description] }
        end
      end
    end

    def enqueue_section
      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
            div do
              h2(class: "card-title text-lg") { "Enqueue Jobs" }
              p(class: "text-sm text-base-content/60") do
                plain "Trigger this job to observe lock behavior"
              end
            end

            div(class: "flex gap-2 flex-wrap") do
              [1, 2, 3, 5, 10].each do |count|
                button_to enqueue_locks_path,
                  params: { job_name: @job_name, count: count },
                  class: "btn btn-primary btn-sm gap-1",
                  "aria-label": "Enqueue #{@job_name} x#{count}" do
                  plain "x#{count}"
                end
              end
            end
          end
        end
      end
    end

    def job_config_card
      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          h2(class: "card-title text-lg mb-2") { "Sidekiq Options" }

          job_class = @job_name.constantize
          opts = job_class.sidekiq_options_hash || {}

          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3") do
            opts.each do |key, value|
              div(class: "flex items-center justify-between p-3 bg-base-200 rounded-lg") do
                span(class: "font-mono text-sm text-base-content/70") { key }
                code(class: "text-sm font-semibold") { value.inspect }
              end
            end
          end
        end
      end
    end

    def lock_details_section
      div(class: "space-y-4") do
        div(class: "flex items-center gap-3") do
          h2(class: "text-2xl font-bold") { "Lock State" }
          span(class: "badge badge-lg #{@lock_digests.any? ? 'badge-warning' : 'badge-ghost'}") do
            plain @lock_digests.size.to_s
          end
        end

        if @lock_digests.empty?
          div(class: "card bg-base-100 shadow-sm") do
            div(class: "card-body items-center text-center py-12") do
              svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", class: "w-12 h-12 text-base-content/20") do |s|
                s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M13.5 10.5V6.75a4.5 4.5 0 119 0v3.75M3.75 21.75h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H3.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z")
              end
              p(class: "text-base-content/40 mt-3") { "No active locks for #{@job_name}" }
              p(class: "text-base-content/30 text-sm") { "Enqueue some jobs above to create locks" }
            end
          end
        else
          @lock_digests.each do |entry|
            lock_detail_card(entry)
          end
        end
      end
    end

    def lock_detail_card(entry)
      state = entry[:state] || {}
      info = entry[:info] || {}

      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body gap-4") do
          # Digest header
          div(class: "flex items-center gap-2") do
            svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", class: "w-5 h-5 text-primary shrink-0") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M7.864 4.243A7.5 7.5 0 0119.5 10.5c0 2.92-.556 5.709-1.568 8.268M5.742 6.364A7.465 7.465 0 004.5 10.5a48.667 48.667 0 00-1.488 8.01M4.5 10.5a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0")
            end
            code(class: "text-sm font-mono break-all text-base-content/70") { entry[:digest].to_s }
          end

          # State grid
          div(class: "grid grid-cols-2 md:grid-cols-4 gap-4") do
            state_stat("Queued", state[:queued].to_s, "info")
            state_stat("Primed", state[:primed].to_s, "warning")
            state_stat("Locked", (state[:locked] || {}).size.to_s, "success")
            state_stat("PTTL", format_pttl(state[:pttl]), "neutral")
          end

          # Locked JIDs
          if (locked = state[:locked]) && locked.any?
            div do
              h4(class: "font-semibold text-sm mb-2") { "Locked JIDs" }
              div(class: "flex flex-wrap gap-2") do
                locked.each do |jid, val|
                  div(class: "badge badge-success badge-outline gap-1 font-mono text-xs") do
                    plain jid
                    span(class: "opacity-50") { "(#{val})" }
                  end
                end
              end
            end
          end

          # Lock Info collapsible
          if info.any?
            div(class: "collapse collapse-arrow bg-base-200 rounded-lg") do
              input(type: "checkbox", class: "peer")
              div(class: "collapse-title text-sm font-medium") { "Lock Info (JSON)" }
              div(class: "collapse-content") do
                div(class: "mockup-code text-xs mt-2") do
                  pre do
                    code { JSON.pretty_generate(info) }
                  end
                end
              end
            end
          end
        end
      end
    end

    def state_stat(label, value, color)
      div(class: "bg-base-200 rounded-lg p-3 text-center") do
        div(class: "text-xs text-base-content/50 uppercase tracking-wide mb-1") { label }
        div(class: "text-xl font-bold text-#{color}") { value }
      end
    end

    def format_pttl(pttl)
      return "none" if pttl.nil? || pttl.to_i == -1
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
