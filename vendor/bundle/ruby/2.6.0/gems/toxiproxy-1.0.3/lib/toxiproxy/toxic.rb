class Toxiproxy
  class Toxic
    attr_reader :name, :type, :stream, :proxy
    attr_accessor :attributes, :toxicity

    def initialize(attrs)
      raise "Toxic type is required" unless attrs[:type]
      @type = attrs[:type]
      @stream = attrs[:stream] || 'downstream'
      @name = attrs[:name] || "#{@type}_#{@stream}"
      @proxy = attrs[:proxy]
      @toxicity = attrs[:toxicity] || 1.0
      @attributes = attrs[:attributes] || {}
    end

    def save
      request = Net::HTTP::Post.new("/proxies/#{proxy.name}/toxics")
      request["Content-Type"] = "application/json"

      request.body = as_json

      response = Toxiproxy.http_request(request)
      Toxiproxy.assert_response(response)

      json = JSON.parse(response.body)
      @attributes = json['attributes']
      @toxicity = json['toxicity']

      self
    end

    def destroy
      request = Net::HTTP::Delete.new("/proxies/#{proxy.name}/toxics/#{name}")
      response = Toxiproxy.http_request(request)
      Toxiproxy.assert_response(response)
      self
    end

    def as_json
      {
        name: name,
        type: type,
        stream: stream,
        toxicity: toxicity,
        attributes: attributes,
      }.to_json
    end
  end
end
