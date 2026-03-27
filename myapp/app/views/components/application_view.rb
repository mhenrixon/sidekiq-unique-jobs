# frozen_string_literal: true

class ApplicationView < ApplicationComponent
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::Flash
  include Phlex::Rails::Helpers::Request
  include Phlex::Rails::Helpers::TurboFrameTag
end
