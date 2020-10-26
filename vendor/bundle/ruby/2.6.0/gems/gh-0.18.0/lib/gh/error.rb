require 'gh'

module GH
  class Error < StandardError
    attr_reader :info

    def initialize(error = nil, payload = nil, info = {})
      info   = info.merge(error.info) if error.respond_to? :info and Hash === error.info
      error  = error.error while error.respond_to? :error
      @info  = info.merge(:error => error, :payload => payload)

      if error
        set_backtrace error.backtrace if error.respond_to? :backtrace
        if error.respond_to? :response and error.response
          case response = error.response
          when Hash
            @info[:response_status]  = response[:status]
            @info[:response_headers] = response[:headers]
            @info[:response_body]    = response[:body]
          when Faraday::Response
            @info[:response_status]  = response.status
            @info[:response_headers] = response.headers
            @info[:response_body]    = response.body
          else
            @info[:response]         = response
          end
        end
      end
    end

    def payload
      info[:payload]
    end

    def error
      info[:error]
    end

    def message
      "GH request failed\n" + info.map { |k,v| entry(k,v) }.join("\n")
    end

    private

    def entry(key, value)
      value = "#{value.class}: #{value.message}" if Exception === value
      value = value.inspect unless String === value
      value.gsub!(/"Basic .+"|(client_(?:id|secret)=)[^&\s]+/, '\1[removed]')
      (key.to_s + ": ").ljust(20) + value
    end
  end

  class TokenInvalid < Error
  end

  def self.Error(conditions)
    Module.new do
      define_singleton_method(:===) do |exception|
        return false unless Error === exception and not exception.info.nil?
        conditions.all? { |k,v| v === exception.info[k]}
      end
    end
  end
end
