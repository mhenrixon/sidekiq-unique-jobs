###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'kwalify/messages'

module Kwalify

  class KwalifyError < StandardError
  end


  class AssertionError < KwalifyError
    def initialize(msg)
      super("*** assertion error: " + msg)
    end
  end


  class BaseError < KwalifyError
    def initialize(message="", path=nil, value=nil, rule=nil, error_symbol=nil)
      super(message)
      @path  = path.is_a?(Array) ? '/'+path.join('/') : path
      @rule  = rule
      @value = value
      @error_symbol = error_symbol
    end
    attr_accessor :error_symbol, :rule, :path, :value
    attr_accessor :filename, :linenum, :column

    def path
      return @path == '' ? "/" : @path
    end

    alias _to_s to_s
    alias message to_s

    def to_s
      s = ''
      s << @filename << ":" if @filename
      s << "#{@linenum}:#{@column} " if @linenum
      s << "[#{path()}] " if @path
      s << _to_s()
      return s
    end

    def <=>(ex)
      #return @linenum <=> ex.linenum
      v = 0
      v = @linenum <=> ex.linenum if @linenum && ex.linenum
      v = @column  <=> ex.column  if v == 0 && @column && ex.column
      v = @path    <=> ex.path    if v == 0
      return v
    end
  end


  class SchemaError < BaseError
    def initialize(message="", path=nil, rule=nil, value=nil, error_symbol=nil)
      super(message, path, rule, value, error_symbol)
    end
  end


  class ValidationError < BaseError
    def initialize(message="", path=nil, rule=nil, value=nil, error_symbol=nil)
      super(message, path, rule, value, error_symbol)
    end
  end


  ## syntax error for YAML and JSON
  class SyntaxError < BaseError  #KwalifyError
    def initialize(msg, linenum=nil, error_symbol=nil)
      super(linenum ? "line #{linenum}: #{msg}" : msg)
      @linenum = linenum
      @error_symbol = error_symbol
    end
    #attr_accessor :linenum, :error_symbol
    def message
      "file: #{@filename}, line #{@linenum}: #{super}"
    end
  end


  ## (obsolete) use Kwalify::SyntaxError instead
  class YamlSyntaxError < SyntaxError
  end


  module ErrorHelper

    #module_function

    def assert_error(message="")
      raise AssertionError.new(message)
    end

    def validate_error(error_symbol, rule, path, val, args=nil)
      msg = _build_message(error_symbol, val, args);
      path = '/'+path.join('/') if path.is_a?(Array)
      return ValidationError.new(msg, path, val, rule, error_symbol)
    end
    module_function :validate_error

    def schema_error(error_symbol, rule, path, val, args=nil)
      msg = _build_message(error_symbol, val, args);
      path = '/'+path.join('/') if path.is_a?(Array)
      return SchemaError.new(msg, path, val, rule, error_symbol)
    end

    def _build_message(message_key, val, args)
      msg = Kwalify.msg(message_key)
      assert_error("message_key=#{message_key.inspect}") unless msg
      msg = msg % args if args
      msg = "'#{val.to_s.gsub(/\n/, '\n')}': #{msg}" if !val.nil? && Types.scalar?(val)
      return msg;
    end
    module_function :_build_message

  end

  extend ErrorHelper

end
