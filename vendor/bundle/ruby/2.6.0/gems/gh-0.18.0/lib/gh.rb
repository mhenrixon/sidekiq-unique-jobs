require 'gh/version'
require 'backports' if RUBY_VERSION < '2.1'
require 'forwardable'

module GH
  autoload :Cache,            'gh/cache'
  autoload :Case,             'gh/case'
  autoload :CustomLimit,      'gh/custom_limit'
  autoload :Error,            'gh/error'
  autoload :Instrumentation,  'gh/instrumentation'
  autoload :LazyLoader,       'gh/lazy_loader'
  autoload :LinkFollower,     'gh/link_follower'
  autoload :MergeCommit,      'gh/merge_commit'
  autoload :Normalizer,       'gh/normalizer'
  autoload :Pagination,       'gh/pagination'
  autoload :Parallel,         'gh/parallel'
  autoload :Remote,           'gh/remote'
  autoload :Response,         'gh/response'
  autoload :ResponseXHeaderFormatter, 'gh/response_x_header_formatter'
  autoload :ResponseWrapper,  'gh/response_wrapper'
  autoload :Stack,            'gh/stack'
  autoload :TokenCheck,       'gh/token_check'
  autoload :Wrapper,          'gh/wrapper'

  def self.with(backend)
    if Hash === backend
      @options ||= {}
      @options, options = @options.merge(backend), @options
      backend = DefaultStack.build(@options)
    end

    if block_given?
      was, self.current = current, backend
      yield
    else
      backend
    end
  ensure
    @options = options if options
    self.current = was if was
  end

  def self.set(options)
    Thread.current[:GH] = nil
    DefaultStack.options.merge! options
  end

  def self.current
    Thread.current[:GH] ||= DefaultStack.new
  end

  def self.current=(backend)
    Thread.current[:GH] = backend
  end

  extend SingleForwardable
  def_delegators :current, :api_host, :[], :reset, :load, :post, :delete, :patch, :put, :in_parallel, :in_parallel?, :options, :head

  def self.method_missing(*args, &block)
    current.public_send(*args, &block)
  end

  DefaultStack = Stack.new do
    use Instrumentation
    use Parallel
    use TokenCheck
    use Pagination
    use LinkFollower
    use MergeCommit
    use LazyLoader
    use Normalizer
    use CustomLimit
    use Remote
  end
end
