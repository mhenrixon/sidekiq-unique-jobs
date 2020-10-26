module GH
  class Pagination < Wrapper
    class Paginated
      include Enumerable

      def initialize(page, url, gh)
        @page, @next_url, @gh = page, url, gh
      end

      def each(&block)
        return enum_for(:each) unless block
        @page.each(&block)
        next_page.each(&block)
      end

      def inspect
        "[#{first.inspect}, ...]"
      end

      def [](value)
        raise TypeError, "index has to be an Integer, got #{value.class}" unless value.is_a? Integer
        return @page[value] if value < @page.size
        next_page[value - @page.size]
      end

      def to_ary
        to_a # replace with better implementation (use in_parallel)
      end

      def headers
        @page.headers
      end

      private

      def next_page
        @next_page ||= @gh[@next_url]
      end
    end

    wraps GH::Normalizer
    double_dispatch

    def fetch_resource(key)
      url = frontend.full_url(key)
      params = url.query_values || {}
      params['per_page'] ||= 100
      url.query_values = params
      super url.request_uri
    end

    def modify_response(response)
      return response unless response.respond_to? :to_ary and response.headers['link'] =~ /<([^>]+)>;\s*rel=\"next\"/
      Paginated.new(response, $1, self)
    end
  end
end
