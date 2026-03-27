# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include DaisyUI
  include IconHelper

  def unsafe_raw(obj)
    return if obj.nil?

    raw(safe(obj))
  end

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
