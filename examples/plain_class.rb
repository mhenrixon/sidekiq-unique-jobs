# frozen_string_literal: true

# :nocov:

class PlainClass
  def self.run(one)
    [one]
  end

  def run(one)
    [one]
  end
end
