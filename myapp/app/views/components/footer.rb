# frozen_string_literal: true

class Footer < ApplicationComponent
  def view_template
    footer(class: "footer footer-center p-6 text-base-content/50 text-sm") do
      p do
        plain "sidekiq-unique-jobs "
        code(class: "font-mono") { SidekiqUniqueJobs::VERSION }
        plain " / Rails #{Rails.version} / Ruby #{RUBY_VERSION}"
      end
    end
  end
end
