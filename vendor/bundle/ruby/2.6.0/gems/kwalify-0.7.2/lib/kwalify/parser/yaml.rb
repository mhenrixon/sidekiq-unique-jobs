###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'kwalify/validator'
require 'kwalify/errors'
require 'kwalify/util'
require 'kwalify/parser/base'



module Kwalify

  module Yaml
  end

end


##
## YAML parser with validator
##
## ex.
##   schema = YAML.load_file('schema.yaml')
##   require 'kwalify'
##   validator = Kwalify::Validator.new(schema)
##   parser = Kwalify::Yaml::Parser.new(validator)  # validator is optional
##   #parser.preceding_alias = true  # optional
##   #parser.data_binding = true     # optional
##   ydoc = parser.parse_file('data.yaml')
##   errors = parser.errors
##   if errors && !errors.empty?
##     errors.each do |e|
##       puts "line=#{e.linenum}, path=#{e.path}, mesg=#{e.message}"
##     end
##   end
##
class Kwalify::Yaml::Parser < Kwalify::BaseParser


  alias reset_scanner reset


  def initialize(validator=nil, properties={})
    @validator = validator.is_a?(Hash) ? Kwalify::Validator.new(validator) : validator
    @data_binding    = properties[:data_binding]    # enable data binding or not
    @preceding_alias = properties[:preceding_alias] # allow preceding alias or not
    @sequence_class  = properties[:sequence_class] || Array
    @mapping_class   = properties[:mapping_class]  || Hash
  end
  attr_accessor :validator        # Validator
  attr_accessor :data_binding     # boolean
  attr_accessor :preceding_alias  # boolean
  attr_accessor :sequence_class   # Class
  attr_accessor :mapping_class    # Class


  def reset_parser()
    @anchors = {}
    @errors = []
    @done = {}
    @preceding_aliases = []
    @location_table = {}    # object_id -> sequence or mapping
    @doc = nil
  end
  attr_reader :errors


  def _error(klass, message, path, linenum, column)
    ex = klass.new(message)
    ex.path = path.is_a?(Array) ? '/' + path.join('/') : path
    ex.linenum = linenum
    ex.column = column
    ex.filename = @filename
    return ex
  end
  private :_error


#  def _validate_error(message, path, linenum=@linenum, column=@column)
#    #message = _build_message(message_key)
#    error = _error(ValidationError, message.to_s, path, linenum, column)
#    @errors << error
#  end
#  private :_validate_error


  def _set_error_info(linenum=@linenum, column=@column, &block)
    len = @errors.length
    yield
    n = @errors.length - len
    (1..n).each do |i|
      error = @errors[-i]
      error.linenum  ||= linenum
      error.column   ||= column
      error.filename ||= @filename
    end if n > 0
  end


  def skip_spaces_and_comments()
    scan(/\s+/)
    while match?(/\#/)
      scan(/.*?\n/)
      scan(/\s+/)
    end
  end


  def document_start?()
    return match?(/---\s/) && @column == 1
  end


  def stream_end?()
    return match?(/\.\.\.\s/) && @column == 1
  end


  def has_next?()
    return !(eos? || stream_end?)
  end


  def parse(input=nil, opts={})
    reset_scanner(input, opts[:filename], opts[:untabify]) if input
    return parse_next()
  end


  def parse_file(filename, opts={})
    opts[:filename] = filename
    return parse(File.read(filename), opts)
  end


  def parse_next()
    reset_parser()
    path = []
    skip_spaces_and_comments()
    if document_start?()
      scan(/.*\n/)
      skip_spaces_and_comments()
    end
    _linenum = @linenum                                                    #*V
    _column = @column                                                      #*V
    rule = @validator ? @validator.rule : nil                              #*V
    uniq_table = nil                                                       #*V
    parent = nil                                                           #*V
    val = parse_block_value(0, rule, path, uniq_table, parent)
    _set_error_info(_linenum, _column) do                                  #*V
      @validator._validate(val, rule, [], @errors, @done, uniq_table, false)  #*V
    end if rule                                                            #*V
    resolve_preceding_aliases(val) if @preceding_alias
    unless eos? || document_start?() || stream_end?()
      raise _syntax_error("document end expected (maybe invalid tab char found).", path)
    end
    @doc = val
    @location_table[-1] = [_linenum, _column]
    return val
  end


  def parse_stream(input, opts={}, &block)
    reset_scanner(input, opts[:filename], opts[:untabify])
    ydocs = block_given? ? nil : []
    while true
      ydoc = parse_next()
      ydocs ? (ydocs << ydoc) : (yield ydoc)
      break if eos? || stream_end?()
      document_start?() or raise "** internal error"
      scan(/.*\n/)
    end
    return ydocs
  end

  alias parse_documents parse_stream


  MAPKEY_PATTERN = /([\w.][-\w.:]*\*?|".*?"|'.*?'|:\w+|=|<<)[ \t]*:\s+/  # :nodoc:

  PRECEDING_ALIAS_PLACEHOLDER = Object.new    # :nodoc:


  def parse_anchor(rule, path, uniq_table, container)
    name = group(1)
    if @anchors.key?(name)
      raise _syntax_error("&#{name}: anchor duplicated.", path,
                          @linenum, @column - name.length)
    end
    skip_spaces_and_comments()
    return name
  end


  def parse_alias(rule, path, uniq_table, container)
    name = group(1)
    if @anchors.key?(name)
      val = @anchors[name]
    elsif @preceding_alias
      @preceding_aliases << [name, rule, path.dup, container,
                             @linenum, @column - name.length - 1]
      val = PRECEDING_ALIAS_PLACEHOLDER
    else
      raise _syntax_error("*#{name}: anchor not found.", path,
                          @linenum, @column - name.length - 1)
    end
    skip_spaces_and_comments()
    return val
  end


  def resolve_preceding_aliases(val)
    @preceding_aliases.each do |name, rule, path, container, _linenum, _column|
      unless @anchors.key?(name)
        raise _syntax_error("*#{name}: anchor not found.", path, _linenum, _column)
      end
      key = path[-1]
      val = @anchors[name]
      raise unless !container.respond_to?('[]') || container[key].equal?(PRECEDING_ALIAS_PLACEHOLDER)
      if container.is_a?(Array)
        container[key] = val
      else
        put_to_map(rule, container, key, val, _linenum, _column)
      end
      _set_error_info(_linenum, _column) do                                #*V
        @validator._validate(val, rule, path, @errors, @done, false)       #*V
      end if rule                                                          #*V
    end
  end


  def parse_block_value(level, rule, path, uniq_table, container)
    skip_spaces_and_comments()
    ## nil
    return nil if @column <= level || eos?
    ## anchor and alias
    name = nil
    if scan(/\&([-\w]+)/)
      name = parse_anchor(rule, path, uniq_table, container)
    elsif scan(/\*([-\w]+)/)
      return parse_alias(rule, path, uniq_table, container)
    end
    ## type
    if scan(/!!?\w+/)
      skip_spaces_and_comments()
    end
    ## sequence
    if match?(/-\s+/)
      if rule && !rule.sequence
        #_validate_error("sequence is not expected.", path)
        rule = nil
      end
      seq = create_sequence(rule, @linenum, @column)
      @anchors[name] = seq if name
      parse_block_seq(seq, rule, path, uniq_table)
      return seq
    end
    ## mapping
    if match?(MAPKEY_PATTERN)
      if rule && !rule.mapping
        #_validate_error("mapping is not expected.", path)
        rule = nil
      end
      map = create_mapping(rule, @linenum, @column)
      @anchors[name] = map if name
      parse_block_map(map, rule, path, uniq_table)
      return map
    end
    ## sequence (flow-style)
    if match?(/\[/)
      if rule && !rule.sequence
        #_validate_error("sequence is not expected.", path)
        rule = nil
      end
      seq = create_sequence(rule, @linenum, @column)
      @anchors[name] = seq if name
      parse_flow_seq(seq, rule, path, uniq_table)
      return seq
    end
    ## mapping (flow-style)
    if match?(/\{/)
      if rule && !rule.mapping
        #_validate_error("mapping is not expected.", path)
        rule = nil
      end
      map = create_mapping(rule, @linenum, @column)
      @anchors[name] = map if name
      parse_flow_map(map, rule, path, uniq_table)
      return map
    end
    ## block text
    if match?(/[|>]/)
      text = parse_block_text(level, rule, path, uniq_table)
      @anchors[name] = text if name
      return text
    end
    ## scalar
    scalar = parse_block_scalar(rule, path, uniq_table)
    @anchors[name] = scalar if name
    return scalar
  end


  def parse_block_seq(seq, seq_rule, path, uniq_table)
    level = @column
    rule = seq_rule ? seq_rule.sequence[0] : nil
    path.push(nil)
    i = 0
    _linenum = @linenum                                                    #*V
    _column  = @column                                                     #*V
    uniq_table = rule ? rule._uniqueness_check_table() : nil               #*V
    while level == @column && scan(/-\s+/)
      path[-1] = i
      skip_spaces_and_comments()                                           #*V
      _linenum2 = @linenum
      _column2  = @column
      val = parse_block_value(level, rule, path, uniq_table, seq)
      add_to_seq(rule, seq, val, _linenum2, _column2)    # seq << val
      _set_error_info(_linenum, _column) do                                #*V
        @validator._validate(val, rule, path, @errors, @done, uniq_table, false) #*V
      end if rule && !val.equal?(PRECEDING_ALIAS_PLACEHOLDER)              #*V
      skip_spaces_and_comments()
      i += 1
      _linenum = @linenum                                                  #*V
      _column  = @column                                                   #*V
    end
    path.pop()
    return seq
  end


  def _parse_map_value(map, map_rule, path, level, key, is_merged, uniq_table,
                       _linenum, _column, _linenum2, _column2)  #:nodoc:
    key = to_mapkey(key)
    path[-1] = key
    #if map.is_a?(Hash) && map.key?(key) && !is_merged
    if map.respond_to?('key?') && map.key?(key) && !is_merged
      rule = map_rule.mapping[key]
      unless rule && rule.default
        raise _syntax_error("mapping key is duplicated.", path)
      end
    end
    #
    if key == '='      # default
      val = level ? parse_block_value(level, nil, path, uniq_table, map) \
                  : parse_flow_value(nil, path, uniq_table, map)
      map.default = val
    elsif key == '<<'  # merge
      classobj = nil
      if map_rule && map_rule.classname
        map_rule = map_rule.dup()
        classobj = map_rule.classobj
        map_rule.classname = nil
        map_rule.classobj = nil
      end
      val = level ? parse_block_value(level, map_rule, path, uniq_table, map) \
                  : parse_flow_value(map_rule, path, uniq_table, map)
      if val.is_a?(Array)
        val.each_with_index do |v, i|
          unless v.is_a?(Hash) || (classobj && val.is_a?(classobj))
            raise _syntax_error("'<<': mapping required.", path + [i])
          end
        end
        values = val
      elsif val.is_a?(Hash) || (classobj && val.is_a?(classobj))
        values = [val]
      else
        raise _syntax_error("'<<': mapping (or sequence of mapping) required.", path)
      end
      #
      values.each do |hash|
        if !hash.is_a?(Hash)
          assert_error "hash=#{hash.inspect}" unless classobj && hash.is_a?(classobj)
          obj = hash
          hash = {}
          obj.instance_variables.each do |name|
            key = name[1..-1]  # '@foo' => 'foo'
            val = obj.instane_variable_get(name)
            hash[key] = val
          end
        end
        for key, val in hash
          path[-1] = key                                                   #*V
          rule = map_rule ? map_rule.mapping[key] : nil                    #*V
          utable = uniq_table ? uniq_table[key] : nil                      #*V
          _validate_map_value(map, map_rule, rule, path, utable,           #*V
                           key, val, _linenum, _column)                    #*V
          put_to_map(rule, map, key, val, _linenum2, _column2)
        end
      end
      is_merged = true
    else               # other
      rule = map_rule ? map_rule.mapping[key] : nil                        #*V
      utable = uniq_table ? uniq_table[key] : nil                          #*V
      val = level ? parse_block_value(level, rule, path, utable, map) \
                  : parse_flow_value(rule, path, utable, map)
      _validate_map_value(map, map_rule, rule, path, utable, key, val,     #*V
                       _linenum, _column)                                  #*V
      put_to_map(rule, map, key, val, _linenum2, _column2)
    end
    return is_merged
  end


  def _validate_map_value(map, map_rule, rule, path, uniq_table, key, val, #*V
                       _linenum, _column)                                  #*V
    if map_rule && !rule                                                   #*V
      #_validate_error("unknown mapping key.", path)                       #*V
      _set_error_info(_linenum, _column) do                                #*V
        error = Kwalify::ErrorHelper.validate_error(:key_undefined,        #*V
                                      rule, path, map, ["#{key}:"])        #*V
        @errors << error                                                   #*V
        #error.linenum = _linenum                                          #*V
        #error.column  = _column                                           #*V
      end                                                                  #*V
    end                                                                    #*V
    _set_error_info(_linenum, _column) do                                  #*V
      @validator._validate(val, rule, path, @errors, @done, uniq_table, false)  #*V
    end if rule && !val.equal?(PRECEDING_ALIAS_PLACEHOLDER)                #*V
  end


  def parse_block_map(map, map_rule, path, uniq_table)
    _start_linenum = @linenum                                              #*V
    _start_column  = @column                                               #*V
    level = @column
    path.push(nil)
    is_merged = false
    while true
      _linenum = @linenum                                                  #*V
      _column  = @column                                                   #*V
      break unless level == @column && scan(MAPKEY_PATTERN)
      key = group(1)
      skip_spaces_and_comments()                                           #*V
      _linenum2 = @linenum                                                 #*V
      _column2  = @column                                                  #*V
      is_merged = _parse_map_value(map, map_rule, path, level, key, is_merged,
                                   uniq_table, _linenum, _column, _linenum2, _column2)
      #skip_spaces_and_comments()
    end
    path.pop()
    _set_error_info(_start_linenum, _start_column) do                      #*V
      @validator._validate_mapping_required_keys(map, map_rule,            #*V
                                                 path, @errors)            #*V
    end if map_rule                                                        #*V
    return map
  end


  def to_mapkey(str)
    if str[0] == ?" || str[0] == ?'
      return str[1..-2]
    else
      return to_scalar(str)
    end
  end
  private :to_mapkey


  def parse_block_scalar(rule, path, uniq_table)
    _linenum = @linenum                                                    #*V
    _column  = @column                                                     #*V
    ch = peep(1)
    if ch == '"' || ch == "'"
      val = scan_string()
      scan(/[ \t]*(?:\#.*)?$/)
    else
      scan(/(.*?)[ \t]*(?:\#.*)?$/)
      #str.rstrip!
      val = to_scalar(group(1))
    end
    val = create_scalar(rule, val, _linenum, _column)                      #*V
    #_set_error_info(_linenum, _column) do                                 #*V
    #  @validator._validate_unique(val, rule, path, @errors, uniq_table)   #*V
    #end if uniq_table                                                     #*V
    skip_spaces_and_comments()
    return val
  end


  def parse_block_text(column, rule, path, uniq_table)
    _linenum = @linenum                                                    #*V
    _column  = @column                                                     #*V
    indicator = scan(/[|>]/)
    chomping = scan(/[-+]/)
    num = scan(/\d+/)
    indent = num ? column + num.to_i - 1 : nil
    unless scan(/[ \t]*(.*?)(\#.*)?\r?\n/)   # /[ \t]*(\#.*)?\r?\n/
      raise _syntax_error("Syntax Error (line break or comment are expected)", path)
    end
    s = group(1)
    is_folded = false
    while match?(/( *)(.*?)(\r?\n)/)
      spaces = group(1)
      text   = group(2)
      nl     = group(3)
      if indent.nil?
        if spaces.length >= column
          indent = spaces.length
        elsif text.empty?
          s << nl
          scan(/.*?\n/)
          next
        else
          @diagnostic = 'text indent in block text may be shorter than that of first line or specified column.'
          break
        end
      else
        if spaces.length < indent && !text.empty?
          @diagnostic = 'text indent in block text may be shorter than that of first line or specified column.'
          break
        end
      end
      scan(/.*?\n/)
      if indicator == '|'
        s << spaces[indent..-1] if spaces.length >= indent
        s << text << nl
      else  # indicator == '>'
        if !text.empty? && spaces.length == indent
          if s.sub!(/\r?\n((\r?\n)+)\z/, '\1')
            nil
          elsif is_folded
            s.sub!(/\r?\n\z/, ' ')
          end
          #s.sub!(/\r?\n\z/, '') if !s.sub!(/\r?\n(\r?\n)+\z/, '\1') && is_folded
          is_folded = true
        else
          is_folded = false
          s << spaces[indent..-1] if spaces.length > indent
        end
        s << text << nl
      end
    end
    ## chomping
    if chomping == '+'
      nil
    elsif chomping == '-'
      s.sub!(/(\r?\n)+\z/, '')
    else
      s.sub!(/(\r?\n)(\r?\n)+\z/, '\1')
    end
    #
    skip_spaces_and_comments()
    val = s
    #_set_error_info(_linenum, _column) do                                  #*V
    #  @validator._validate_unique(val, rule, path, @errors, uniq_table)    #*V
    #end if uniq_table                                                      #*V
    return val
  end


  def parse_flow_value(rule, path, uniq_table, container)
    skip_spaces_and_comments()
    ## anchor and alias
    name = nil
    if scan(/\&([-\w]+)/)
      name = parse_anchor(rule, path, uniq_table, container)
    elsif scan(/\*([-\w]+)/)
      return parse_alias(rule, path, uniq_table, container)
    end
    ## type
    if scan(/!!?\w+/)
      skip_spaces_and_comments()
    end
    ## sequence
    if match?(/\[/)
      if rule && !rule.sequence                                            #*V
        #_validate_error("sequence is not expected.", path)                #*V
        rule = nil                                                         #*V
      end                                                                  #*V
      seq = create_sequence(rule, @linenum, @column)
      @anchors[name] = seq if name
      parse_flow_seq(seq, rule, path, uniq_table)
      return seq
    end
    ## mapping
    if match?(/\{/)
      if rule && !rule.mapping                                             #*V
        #_validate_error("mapping is not expected.", path)                 #*V
        rule = nil                                                         #*V
      end                                                                  #*V
      map = create_mapping(rule, @linenum, @column)
      @anchors[name] = map if name
      parse_flow_map(map, rule, path, uniq_table)
      return map
    end
    ## scalar
    scalar = parse_flow_scalar(rule, path, uniq_table)
    @anchors[name] = scalar if name
    return scalar
  end


  def parse_flow_seq(seq, seq_rule, path, uniq_table)
    #scan(/\[\s*/)
    scan(/\[/)
    skip_spaces_and_comments()
    if scan(/\]/)
      nil
    else
      rule = seq_rule ? seq_rule.sequence[0] : nil                         #*V
      uniq_table = rule ? rule._uniqueness_check_table() : nil             #*V
      path.push(nil)
      i = 0
      while true
        path[-1] = i
        _linenum = @linenum                                                #*V
        _column  = @column                                                 #*V
        val = parse_flow_value(rule, path, uniq_table, seq)
        add_to_seq(rule, seq, val, _linenum, _column)  # seq << val
        _set_error_info(_linenum, _column) do                              #*V
          @validator._validate(val, rule, path, @errors, @done, uniq_table, false)  #*V
        end if rule && !val.equal?(PRECEDING_ALIAS_PLACEHOLDER)            #*V
        skip_spaces_and_comments()
        break unless scan(/,\s+/)
        i += 1
        if match?(/\]/)
          raise _syntax_error("sequence item required (or last comma is extra).", path)
        end
      end
      path.pop()
      unless scan(/\]/)
        raise _syntax_error("flow sequence is not closed by ']'.", path)
      end
    end
    skip_spaces_and_comments()
    return seq
  end


  def parse_flow_map(map, map_rule, path, uniq_table)
    #scan(/\{\s*/)  # not work?
    _start_linenum = @linenum                                              #*V
    _start_column  = @column                                               #*V
    scan(/\{/)
    skip_spaces_and_comments()
    if scan(/\}/)
      nil
    else
      path.push(nil)
      is_merged = false
      while true
        _linenum = @linenum                                                #*V
        _column  = @column                                                 #*V
        unless scan(MAPKEY_PATTERN)
          raise _syntax_error("mapping key is expected.", path)
        end
        key = group(1)
        skip_spaces_and_comments()
        _linenum2 = @linenum                                               #*V
        _column2  = @column                                                #*V
        is_merged = _parse_map_value(map, map_rule, path, nil, key, is_merged,
                           uniq_table, _linenum, _column, _linenum2, _column2)
        #skip_spaces_and_comments()
        break unless scan(/,\s+/)
      end
      path.pop()
      unless scan(/\}/)
        raise _syntax_error("flow mapping is not closed by '}'.", path)
      end
    end
    skip_spaces_and_comments()
    _set_error_info(_start_linenum, _start_column) do                      #*V
      @validator._validate_mapping_required_keys(map, map_rule, path, @errors)  #*V
    end if map_rule                                                        #*V
    return map
  end


  def parse_flow_scalar(rule, path, uniq_table)
    ch = peep(1)
    _linenum = @linenum                                                    #*V
    _column  = @column                                                     #*V
    if ch == '"' || ch == "'"
      val = scan_string()
    else
      str = scan(/[^,\]\}\#]*/)
      if match?(/,\S/)
        while match?(/,\S/)
          str << scan(/./)
          str << scan(/[^,\]\}\#]*/)
        end
      end
      str.rstrip!
      val = to_scalar(str)
    end
    val = create_scalar(rule, val, _linenum, _column)                      #*V
    #_set_error_info(_linenum, _column) do                                  #*V
    #  @validator._validate_unique(val, rule, path, @errors, uniq_table)    #*V
    #end if uniq_table                                                      #*V
    skip_spaces_and_comments()
    return val
  end


  ####


  def to_scalar(str)
    case str
    when nil                ;  val = nil
    when /\A-?\d+\.\d+\z/   ;  val = str.to_f
    when /\A-?\d+\z/        ;  val = str.to_i
    when /\A(true|yes)\z/   ;  val = true
    when /\A(false|no)\z/   ;  val = false
    when /\A(null|~)\z/     ;  val = nil
    when /\A"(.*)"\z/       ;  val = $1
    when /\A'(.*)'\z/       ;  val = $1
    when /\A:(\w+)\z/       ;  val = $1.intern
    when /\A(\d\d\d\d)-(\d\d)-(\d\d)(?: (\d\d):(\d\d):(\d\d))?\z/
      year, month, day, hour, min, sec = $1, $2, $3, $4, $5, $6
      if hour
        val = Time.mktime(year, month, day, hour, min, sec)
      else
        val = Date.new(year.to_i, month.to_i, day.to_i)
      end
      ## or
      #params = [$1, $2, $3, $4, $5, $6]
      #val = Time.mktime(*params)
    else
      val = str.empty? ? nil : str
    end
    skip_spaces_and_comments()
    return val
  end


  ##

  protected


  def create_sequence(rule, linenum, column)
    seq = @sequence_class.new
    @location_table[seq.__id__] = []
    return seq
  end


  def create_mapping(rule, linenum, column)
    if rule && rule.classobj && @data_binding
      classobj = rule.classobj
      map = classobj.new
    else
      classobj = nil
      map = @mapping_class.new   # {}
    end
    @location_table[map.__id__] = hash = {}
    hash[:classobj] = classobj if classobj
    return map
  end


  def create_scalar(rule, value, linenum, column)
    return value
  end


  def add_to_seq(rule, seq, val, linenum, column)
    seq << val
    @location_table[seq.__id__] << [linenum, column]
  end


  def put_to_map(rule, map, key, val, linenum, column)
    #if map.is_a?(Hash)
    #  map[key] = val
    #elsif map.respond_to?(name="#{key}=")
    #  map.__send__(name, val)
    #elsif map.respond_to?('[]=')
    #  map[key] = val
    #else
    #  map.instance_variable_set("@#{key}", val)
    #end
    map[key] = val
    @location_table[map.__id__][key] = [linenum, column]
  end


  def _getclass(classname)
    mod = Object
    classname.split(/::/).each do |modname|
      mod = mod.const_get(modname)   # raises NameError when module not found
    end
    return mod
  end


  public


  def location(path)
    if path.empty? || path == '/'
      return @location_table[-1]    # return value is [linenum, column]
    end
    if path.is_a?(Array)
      items = path.collect { |item| to_scalar(item) }
    elsif path.is_a?(String)
      items = path.split('/').collect { |item| to_scalar(item) }
      items.shift if path[0] == ?/  # delete empty string on head
    else
      raise ArgumentError.new("path should be Array or String.")
    end
    last_item = items.pop()
    c = @doc                        # collection
    items.each do |item|
      if c.is_a?(Array)
        c = c[item.to_i]
      elsif c.is_a?(Hash)
        c = c[item]
      elsif (table = @location_table[c.__id__]) && table[:classobj]
        if c.respond_to?(item)
          c = c.__send__(item)
        elsif c.respond_to?("[]=")
          c = c[item]
        else
          assert false
        end
      else
        #assert false
        raise ArgumentError.new("#{path.inspect}: invalid path.")
      end
    end
    collection = @location_table[c.__id__]
    return nil if collection.nil?
    index = c.is_a?(Array) ? last_item.to_i : last_item
    return collection[index]  # return value is [linenum, column]
  end


  def set_errors_linenum(errors)
    errors.each do |error|
      error.linenum, error.column = location(error.path)
    end
  end


end
