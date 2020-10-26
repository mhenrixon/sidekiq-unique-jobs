require 'gh'

module GH
  module Case
    def respond_to(method) proc { |o| o.respond_to? method } end
    private :respond_to
  end
end
