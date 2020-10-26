###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

class CommandOptionError < StandardError
  def initialize(option, error_symbol, message=nil)
    if !message
      case error_symbol
      when :no_argument
        message = "-%s: argument required." % option
      when :unknown_option
        message = "-%s: unknown option." % option
      when :invalid_property
        message = "-%s: invalid property." % option
      else
        message = "*** internal error(optchar=#{option}, error_symbol=#{error_symbol}) ***"
      end
    end
    super(message)
    @option = option
    @error_symbol = error_symbol
  end

  attr_reader :option, :error_symbol
end


##
##  ex.
##    ## create parser
##    arg_none     = "hv"      # ex. -h -v
##    arg_required = "xf"      # ex. -x suffix -f filename
##    arg_optional = "i"       # ex. -i  (or -i10)
##    parser = CommandOptionParser.new(arg_none, arg_required, arg_optional)
##
##    ## parse options
##    argv = %w[-h -v -f filename -i 10 aaa bbb]
##    options, properties = parser.parse(argv)
##    p options   #=> { ?h=>true, ?v=>true, ?f=>"filename", ?i=>true }
##    p argv      #=> ["10", "aaa", "bbb"]
##
##    ## parse options #2
##    argv = %w[-hvx.txt -ffilename -i10 aaa bbb]
##    options, properties = parser.parse(argv)
##    p options   #=> { ?h=>true, ?v=>true, ?x=>".txt", ?f=>"filename", ?i=>10 }
##    p argv      #=> ["aaa", "bbb"]
##
##    ## parse properties
##    argv = %w[-hi --index=10 --user-name=foo --help]
##    options, properties = parser.parse(argv)
##    p options     #=> {?h=>true, ?i=>true}
##    p properties  #=> {"index"=>"10", "user-name"=>"foo", "help"=>nil}
##
##    ## parse properties with auto-convert
##    argv = %w[-hi --index=10 --user-name=foo --help]
##    options, properties = parser.parse(argv, true)
##    p options     #=> {?h=>true, ?i=>true}
##    p properties  #=> {:index=>10, :user_name=>foo, :help=>true}
##
##    ## -a: unknown option.
##    argv = %w[-abc]
##    begin
##       options, properties = parser.parse(argv)
##    rescue CommandOptionError => ex
##       $stderr.puts ex.message     # -a: unknown option.
##    end
##
##    ## -f: argument required.
##    argv = %w[-f]
##    begin
##       options, properties = parser.parse(argv)
##    rescue CommandOptionError => ex
##       $stderr.puts ex.message     # -f: argument required.
##    end
##
##    ## --@prop=10: invalid property.
##    argv = %w[--@prop=10]
##    begin
##       options, properties = parser.parse(argv)
##    rescue CommandOptionError => ex
##       $stderr.puts ex.message     # --@prop=10: invalid property.
##    end
##

class CommandOptionParser

  ## arg_none:      option string which takes no argument
  ## arg_required:  option string which takes argument
  ## arg_otpional:  option string which may takes argument optionally
  def initialize(arg_none=nil, arg_required=nil, arg_optional=nil)
    @arg_none      = arg_none     || ""
    @arg_required  = arg_required || ""
    @arg_optional  = arg_optional || ""
  end


  def self.to_value(str)
    case str
    when nil, "null", "nil"         ;   return nil
    when "true", "yes"              ;   return true
    when "false", "no"              ;   return false
    when /\A\d+\z/                  ;   return str.to_i
    when /\A\d+\.\d+\z/             ;   return str.to_f
    when /\/(.*)\//                 ;   return Regexp.new($1)
    when /\A'.*'\z/, /\A".*"\z/     ;   return eval(str)
    else                            ;   return str
    end
  end


  ## argv:: array of string
  ## auto_convert::  if true, convert properties value to int, boolean, string, regexp, ... (default false)
  def parse(argv, auto_convert=false)
    options = {}
    properties = {}
    while argv[0] && argv[0][0] == ?-
      optstr = argv.shift
      optstr = optstr[1, optstr.length-1]
      #
      if optstr[0] == ?-    ## property
        unless optstr =~ /\A\-([-\w]+)(?:=(.*))?/
          raise CommandOptionError.new(optstr, :invalid_property)
        end
        prop_name = $1;  prop_value = $2
        if auto_convert
          key   = prop_name.gsub(/-/, '_').intern
          value = prop_value.nil? ? true : CommandOptionParser.to_value(prop_value)
          properties[key] = value
        else
          properties[prop_name] = prop_value
        end
        #
      else                  ## options
        while optstr && !optstr.empty?
          optchar = optstr[0]
          optstr[0,1] = ""
          #puts "*** debug: optchar=#{optchar.chr}, optstr=#{optstr.inspect}"
          if @arg_none.include?(optchar)
            options[optchar] = true
          elsif @arg_required.include?(optchar)
            arg = optstr.empty? ? argv.shift : optstr
            raise CommandOptionError.new(optchar.chr, :no_argument) unless arg
            options[optchar] = arg
            optstr = nil
          elsif @arg_optional.include?(optchar)
            arg = optstr.empty? ? true : optstr
            options[optchar] = arg
            optstr = nil
          else
            raise CommandOptionError.new(optchar.chr, :unknown_option)
          end
        end
      end
      #
    end  # end of while

    return options, properties
  end

end


if __FILE__ == $0
  ## create parser
  arg_none     = "hv"      # ex. -h -v
  arg_required = "xf"      # ex. -x suffix -f filename
  arg_optional = "i"       # ex. -i  (or -i10)
  parser = CommandOptionParser.new(arg_none, arg_required, arg_optional)

  ## parse options
  argv = %w[-h -v -f filename -i 10 aaa bbb]
  options, properties = parser.parse(argv)
  p options   #=> { ?h=>true, ?v=>true, ?f=>"filename", ?i=>true }
  p argv      #=> ["10", "aaa", "bbb"]

  ## parse options #2
  argv = %w[-hvx.txt -ffilename -i10 aaa bbb]
  options, properties = parser.parse(argv)
  p options   #=> { ?h=>true, ?v=>true, ?x=>".txt", ?f=>"filename", ?i=>"10" }
  p argv      #=> ["aaa", "bbb"]

  ## parse properties
  argv = %w[-hi --index=10 --user-name=foo --help]
  options, properties = parser.parse(argv)
  p options     #=> {?h=>true, ?i=>true}
  p properties  #=> {"index"=>"10", "user-name"=>"foo", "help"=>nil}

  ## parse properties with auto-convert
  argv = %w[-hi --index=10 --user-name=foo --help]
  options, properties = parser.parse(argv, true)
  p options     #=> {?h=>true, ?i=>true}
  p properties  #=> {:index=>10, :user_name=>foo, :help=>true}

  ## -a: unknown option.
  argv = %w[-abc]
  begin
    options, properties = parser.parse(argv)
  rescue CommandOptionError => ex
    $stderr.puts ex.message     # -a: unknown option.
  end

  ## -f: argument required.
  argv = %w[-f]
  begin
    options, properties = parser.parse(argv)
  rescue CommandOptionError => ex
    $stderr.puts ex.message     # -f: argument required.
  end

  ## --@prop=10: invalid property.
  argv = %w[--@prop=10]
  begin
    options, properties = parser.parse(argv)
  rescue CommandOptionError => ex
    $stderr.puts ex.message     # --@prop=10: invalid property.
  end

end
