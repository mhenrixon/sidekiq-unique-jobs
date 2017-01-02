class Guest
  GUEST_NAME = 'Guest Visitor'.freeze
  GUEST_EMAIL = 'unknown@domain.com'.freeze

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
