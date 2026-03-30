# frozen_string_literal: true

module Locks
  class ShowView < ApplicationView
    include Phlex::Rails::Helpers::ButtonTo
    include Phlex::Rails::Helpers::LinkTo

    LOCK_TYPE_STYLES = IndexView::LOCK_TYPE_STYLES

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
              hero("home", variant: :mini, class: "w-4 h-4")
              plain "Dashboard"
            end
          end
          li(class: "font-medium") { @job_name }
        end
      end
    end

    def job_header
      lock_type = @job_info[:lock_type]
      style = LOCK_TYPE_STYLES.fetch(lock_type, { badge: "badge-ghost", icon: "lock-closed" })

      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          div(class: "flex flex-col sm:flex-row sm:items-center gap-3") do
            div(class: "p-3 rounded-xl bg-base-200 w-fit") do
              hero(style[:icon], variant: :outline, class: "w-8 h-8 text-primary")
            end
            div do
              h1(class: "text-3xl font-bold") { @job_name }
              div(class: "badge #{style[:badge]} badge-lg font-mono mt-1") do
                plain lock_type.to_s
              end
            end
          end
          p(class: "text-base-content/60 mt-2") { @job_info[:description] }
        end
      end
    end

    def enqueue_section
      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body") do
          div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
            div do
              h2(class: "card-title text-lg gap-2") do
                hero("rocket-launch", variant: :outline, class: "w-5 h-5")
                plain "Enqueue Jobs"
              end
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
          h2(class: "card-title text-lg mb-2 gap-2") do
            hero("cog-6-tooth", variant: :outline, class: "w-5 h-5")
            plain "Sidekiq Options"
          end

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
              hero("lock-open", variant: :outline, class: "w-12 h-12 text-base-content/20")
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
      info = entry[:info] || {}
      locked_jids = entry[:locked_jids] || []
      pttl = entry[:pttl]

      div(class: "card bg-base-100 shadow-sm") do
        div(class: "card-body gap-4") do
          div(class: "flex items-center gap-2") do
            hero("finger-print", variant: :outline, class: "w-5 h-5 text-primary shrink-0")
            code(class: "text-sm font-mono break-all text-base-content/70") { entry[:digest].to_s }
          end

          div(class: "grid grid-cols-2 gap-4") do
            state_stat("Holders", locked_jids.size.to_s, "success")
            state_stat("PTTL", format_pttl(pttl), "neutral")
          end

          if locked_jids.any?
            div do
              h4(class: "font-semibold text-sm mb-2 flex items-center gap-1") do
                hero("key", variant: :mini, class: "w-4 h-4")
                plain "Locked JIDs"
              end
              div(class: "flex flex-wrap gap-2") do
                locked_jids.each do |jid|
                  div(class: "badge badge-success badge-outline gap-1 font-mono text-xs") do
                    plain jid
                  end
                end
              end
            end
          end

          if info.any?
            div(class: "collapse collapse-arrow bg-base-200 rounded-lg") do
              input(type: "checkbox", class: "peer")
              div(class: "collapse-title text-sm font-medium flex items-center gap-1") do
                hero("code-bracket", variant: :mini, class: "w-4 h-4")
                plain "Lock Info (JSON)"
              end
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

    STAT_COLORS = {
      "info" => "text-info",
      "warning" => "text-warning",
      "success" => "text-success",
      "neutral" => "text-neutral",
    }.freeze

    def state_stat(label, value, color)
      color_class = STAT_COLORS.fetch(color, "text-base-content")
      div(class: "bg-base-200 rounded-lg p-3 text-center") do
        div(class: "text-xs text-base-content/50 uppercase tracking-wide mb-1") { label }
        div(class: "text-xl font-bold #{color_class}") { value }
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
