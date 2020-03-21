# frozen_string_literal: true

class Guest
  GUEST_NAME = "Guest Visitor"
  GUEST_EMAIL = "unknown@domain.com"

  def name
    GUEST_NAME
  end

  def email
    GUEST_EMAIL
  end

  def appear; end

  def disappear; end

  def away; end
end
