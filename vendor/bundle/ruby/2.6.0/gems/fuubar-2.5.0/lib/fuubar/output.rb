# frozen_string_literal: true

require 'delegate'

class Fuubar < RSpec::Core::Formatters::BaseTextFormatter
class Output < ::Delegator
  def initialize(output, force_tty = false)
    @raw_output = output
    @force_tty  = force_tty
  end

  def __getobj__
    @raw_output
  end

  def tty?
    @force_tty || @raw_output.tty?
  end
end
end
