# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include MoneyRails::ActionViewExtension
  helper :application

  default from: "mikael@mhenrixon.com"

  layout "mailer"
end
