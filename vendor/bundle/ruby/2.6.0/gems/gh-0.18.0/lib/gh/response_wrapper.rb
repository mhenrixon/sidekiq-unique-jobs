require 'gh'
require 'delegate'

module GH
  ResponseWrapper = DelegateClass(Response) unless const_defined?
  class ResponseWrapper
    def to_gh
      self
    end
  end
end
