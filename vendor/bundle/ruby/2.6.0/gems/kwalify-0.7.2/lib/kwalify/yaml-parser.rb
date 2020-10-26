###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'kwalify/messages'
require 'kwalify/errors'
require 'kwalify/types'

require 'date'


module Kwalify

  ##
  ## base class of yaml parser
  ##
  ## ex.
  ##   str = ARGF.read()
  ##   parser = Kwalify::PlainYamlParser.new(str)
  ##   doc = parser.parse()
  ##   p doc
  ##
  class PlainYamlParser

    class Alias
      def initialize(label, linenum)
        @label   = label
        @linenum = linenum
      end
      attr_reader :label, :linenum
    end


    def initialize(yaml_str)
      @lines = yaml_str.to_a()
      @line  = nil
      @linenum = 0
      @anchors = {}
      @aliases = {}
    end


    def parse()
      data = parse_child(0)
      if data.nil? && @end_flag == '---'
        data = parse_child(0)
      end
      resolve_aliases(data) unless @aliases.empty?
      return data
    end


    def has_next?
      return @end_flag != 'EOF'
    end


    def parse_all
      list = []
      while has_next()
        doc = parse()
        list << doc
      end
      return list
    end


    protected


    def create_sequence(linenum=nil)
      return []
    end

    def add_to_seq(seq, value, linenum)
      seq << value
    end

    def set_seq_at(seq, i, value, linenum)
      seq[i] = value
    end

    def create_mapping(linenum=nil)
      return {}
    end

    def add_to_map(map, key, value, linenum)
      map[key] = value
    end

    def set_map_with(map, key, value, linenum)
      map[key] = value
    end

    def set_default(map, value, linenum)
      map.value = value
    end

    def merge_map(map, map2, linenum)
      map2.each do |key, val|
        map[key] = value unless map.key?(key)
      end
    end

    def create_scalar(value, linenum=nil)
      return value
    end


    def current_line
      return @line
    end

    def current_linenum
      return @linenum
    end


    private


    def getline
      line = _getline()
      line = _getline() while line && line =~ /^\s*($|\#)/
        return line
    end

    def _getline
      @line = @lines[@linenum]
      @linenum += 1
      case @line
      when nil             ; @end_flag = 'EOF'
      when /^\.\.\.$/      ; @end_flag = '...'; @line = nil
      when /^---(\s+.*)?$/ ; @end_flag = '---'; @line = nil
      else                 ; @end_flag = nil
      end
      return @line
    end


    def reset_sbuf(str)
      @sbuf = str[-1] == ?\n ? str : str + "\n"
      @index = -1
    end


    def _getchar
      @index += 1
      ch = @sbuf[@index]
      while ch.nil?
        break if (line = getline()).nil?
        reset_sbuf(line)
        @index += 1
        ch = @sbuf[@index]
      end
      return ch
    end

    def getchar
      ch = _getchar()
      ch = _getchar() while ch && white?(ch)
      return ch
    end

    def getchar_or_nl
      ch = _getchar()
      ch = _getchar() while ch && white?(ch) && ch != ?\n
      return ch
    end

    def current_char
      return @sbuf[@index]
    end

    def getlabel
      if @sbuf[@index..-1] =~ /\A\w[-\w]*/
        label = $&
        @index += label.length
      else
        label = nil
      end
      return label
    end

    #--
    #def syntax_error(error_symbol, linenum=@linenum)
    #  msg = Kwalify.msg(error_symbol) % [linenum]
    #  return Kwalify::YamlSyntaxError.new(msg, linenum,error_symbol)
    #end
    #++
    def syntax_error(error_symbol, arg=nil, linenum=@linenum)
      msg = Kwalify.msg(error_symbol)
      msg = msg % arg.to_a unless arg.nil?
      return Kwalify::YamlSyntaxError.new(msg, linenum, error_symbol)
    end

    def parse_child(column)
      line = getline()
      return create_scalar(nil) if !line
      line =~ /^( *)(.*)/
      indent = $1.length
      return create_scalar(nil) if indent < column
      value = $2
      return parse_value(column, value, indent)
    end


    def parse_value(column, value, value_start_column)
      case value
      when /^-( |$)/
        data = parse_sequence(value_start_column, value)
      when /^(:?:?[-.\w]+\*?|'.*?'|".*?"|=|<<) *:( |$)/
        #when /^:?["']?[-.\w]+["']? *:( |$)/			#'
        data = parse_mapping(value_start_column, value)
      when /^\[/, /^\{/
        data = parse_flowstyle(column, value)
      when /^\&[-\w]+( |$)/
        data = parse_anchor(column, value)
      when /^\*[-\w]+( |$)/
        data = parse_alias(column, value)
      when /^[|>]/
        data = parse_block_text(column, value)
      when /^!/
        data = parse_tag(column, value)
      when /^\#/
          data = parse_child(column)
      else
        data = parse_scalar(column, value)
      end
      return data
    end

    def white?(ch)
      return ch == ?\  || ch == ?\t || ch == ?\n || ch == ?\r
    end


    ##
    ## flowstyle     ::=  flow_seq | flow_map | flow_scalar | alias
    ##
    ## flow_seq      ::=  '[' [ flow_seq_item { ',' sp flow_seq_item } ] ']'
    ## flow_seq_item ::=  flowstyle
    ##
    ## flow_map      ::=  '{' [ flow_map_item { ',' sp flow_map_item } ] '}'
    ## flow_map_item ::=  flowstyle ':' sp flowstyle
    ##
    ## flow_scalar   ::=  string | number | boolean | symbol | date
    ##

    def parse_flowstyle(column, value)
      reset_sbuf(value)
      getchar()
      data = parse_flow(0)
      ch = current_char
      assert ch == ?] || ch == ?}
      ch = getchar_or_nl()
      unless ch == ?\n || ch == ?# || ch.nil?
        #* key=:flow_hastail  msg="flow style sequence is closed but got '%s'."
        raise syntax_error(:flow_hastail, [ch.chr])
      end
      getline() if !ch.nil?
      return data
    end

    def parse_flow(depth)
      ch = current_char()
      #ch = getchar()
      if ch.nil?
        #* key=:flow_eof  msg="found EOF when parsing flow style."
        rase syntax_error(:flow_eof)
      end
      ## alias
      if ch == ?*
        _getchar()
        label = getlabel()
        unless label
          #* key=:flow_alias_label  msg="alias name expected."
          rase syntax_error(:flow_alias_label)
        end
        data = @anchors[label]
        unless data
          data = register_alias(label)
          #raise syntax_error("anchor '#{label}' not found (cannot refer to backward or child anchor).")
        end
        return data
      end
      ## anchor
      label = nil
      if ch == ?&
        _getchar()
        label = getlabel()
        unless label
          #* key=:flow_anchor_label  msg="anchor name expected."
          rase syntax_error(:flow_anchor_label)
        end
        ch = current_char()
        ch = getchar() if white?(ch)
      end
      ## flow data
      if ch == ?[
        data = parse_flow_seq(depth)
      elsif ch == ?{
        data = parse_flow_map(depth)
      else
        data = parse_flow_scalar(depth)
      end
      ## register anchor
      register_anchor(label, data) if label
      return data
    end

    def parse_flow_seq(depth)
      assert current_char() == ?[
      seq = create_sequence()  # []
      ch = getchar()
      if ch != ?}
        linenum = current_linenum()
        #seq << parse_flow_seq_item(depth + 1)
        add_to_seq(seq, parse_flow_seq_item(depth + 1), linenum)
        while (ch = current_char()) == ?,
          ch = getchar()
          if ch == ?]
            #* key=:flow_noseqitem  msg="sequence item required (or last comma is extra)."
            raise syntax_error(:flow_noseqitem)
          end
          #break if ch == ?]
          linenum = current_linenum()
          #seq << parse_flow_seq_item(depth + 1)
          add_to_seq(seq, parse_flow_seq_item(depth + 1), linenum)
        end
      end
      unless current_char() == ?]
        #* key=:flow_seqnotclosed  msg="flow style sequence requires ']'."
        raise syntax_error(:flow_seqnotclosed)
      end
      getchar() if depth > 0
      return seq
    end

    def parse_flow_seq_item(depth)
      return parse_flow(depth)
    end

    def parse_flow_map(depth)
      assert current_char() == ?{          #}
      map = create_mapping()  # {}
      ch = getchar()
      if ch != ?}
        linenum = current_linenum()
        key, value = parse_flow_map_item(depth + 1)
        #map[key] = value
        add_to_map(map, key, value, linenum)
        while (ch = current_char()) == ?,
          ch = getchar()
          if ch == ?}
            #* key=:flow_mapnoitem  msg="mapping item required (or last comma is extra)."
            raise syntax_error(:flow_mapnoitem)
          end
          #break if ch == ?}
          linenum = current_linenum()
          key, value = parse_flow_map_item(depth + 1)
          #map[key] = value
          add_to_map(map, key, value, linenum)
        end
      end
      unless current_char() == ?}
        #* key=:flow_mapnotclosed  msg="flow style mapping requires '}'."
        raise syntax_error(:flow_mapnotclosed)
      end
      getchar() if depth > 0
      return map
    end

    def parse_flow_map_item(depth)
      key = parse_flow(depth)
      unless (ch = current_char()) == ?:
        $stderr.puts "*** debug: key=#{key.inspect}"
        s = ch ? "'#{ch.chr}'" : "EOF"
        #* key=:flow_nocolon  msg="':' expected but got %s."
        raise syntax_error(:flow_nocolon, [s])
      end
      getchar()
      value = parse_flow(depth)
      return key, value
    end

    def parse_flow_scalar(depth)
      case ch = current_char()
      when ?", ?'         #"
        endch = ch
        s = ''
        while (ch = _getchar()) != nil && ch != endch
          if ch == ?\\
            ch = _getchar()
            if ch.nil?
              #* key=:flow_str_notclosed  msg="%s: string not closed."
              raise syntax_error(:flow_str_notclosed, endch == ?" ? "'\"'" : '"\'"')
            end
            if endch == ?"
              case ch
              when ?\\ ;  s << "\\"
              when ?"  ;  s << "\""
              when ?n  ;  s << "\n"
              when ?r  ;  s << "\r"
              when ?t  ;  s << "\t"
              when ?b  ;  s << "\b"
              else     ;  s << "\\" << ch.chr
              end
            elsif endch == ?'
              case ch
              when ?\\ ;  s << '\\'
              when ?'  ;  s << '\''
              else     ;  s << '\\' << ch.chr
              end
            end
          else
            s << ch.chr
          end
        end
        getchar()
        scalar = s
      else
        s = ch.chr
        while (ch = _getchar()) != nil && ch != ?: && ch != ?, && ch != ?] && ch != ?}
          s << ch.chr
        end
        scalar = to_scalar(s.strip)
      end
      return create_scalar(scalar)
    end


    def parse_tag(column, value)
      assert value =~ /^!\S+/
      value =~ /^!(\S+)((\s+)(.*))?$/
      tag    = $1
      space  = $3
      value2 = $4
      if value2 && !value2.empty?
        value_start_column = column + 1 + tag.length + space.length
        data = parse_value(column, value2, value_start_column)
      else
        data = parse_child(column)
      end
      return data
    end


    def parse_anchor(column, value)
      assert value =~ /^\&([-\w]+)(( *)(.*))?$/
      label  = $1
      space  = $3
      value2 = $4
      if value2 && !value2.empty?
        #column2 = column + 1 + label.length + space.length
        #data = parse_value(column2, value2)
        value_start_column = column + 1 + label.length + space.length
        data = parse_value(column, value2, value_start_column)
      else
        #column2 = column + 1
        #data = parse_child(column2)
        data = parse_child(column)
      end
      register_anchor(label, data)
      return data
    end

    def register_anchor(label, data)
      if @anchors[label]
        #* key=:anchor_duplicated  msg="anchor '%s' is already used."
        raise syntax_error(:anchor_duplicated, [label])
      end
      @anchors[label] = data
    end

    def parse_alias(column, value)
      assert value =~ /^\*([-\w]+)(( *)(.*))?$/
      label  = $1
      space  = $3
      value2 = $4
      if value2 && !value2.empty? && value2[0] != ?\#
        #* key=:alias_extradata  msg="alias cannot take any data."
        raise syntax_error(:alias_extradata)
      end
      data = @anchors[label]
      unless data
        data = register_alias(label)
        #raise syntax_error("anchor '#{label}' not found (cannot refer to backward or child anchor).")
      end
      getline()
      return data
    end

    def register_alias(label)
      @aliases[label] ||= 0
      @aliases[label] += 1
      return Alias.new(label, @linenum)
    end


    def resolve_aliases(data)
      @resolved ||= {}
      return if @resolved[data.__id__]
      @resolved[data.__id__] = data
      case data
      when Array
        seq = data
        seq.each_with_index do |val, i|
          if val.is_a?(Alias)
            anchor = val
            if @anchors.key?(anchor.label)
              #seq[i] = @anchors[anchor.label]
              set_seq_at(seq, i, @anchors[anchor.label], anchor.linenum)
            else
              #* key=:anchor_notfound  msg="anchor '%s' not found"
              raise syntax_error(:anchor_notfound, [anchor.label], val.linenum)
            end
          elsif val.is_a?(Array) || val.is_a?(Hash)
            resolve_aliases(val)
          end
        end
      when Hash
        map = data
        map.each do |key, val|
          if val.is_a?(Alias)
            if @anchors.key?(val.label)
              anchor = val
              #map[key] = @anchors[anchor.label]
              set_map_with(map, key, @anchors[anchor.label], anchor.linenum)
            else
              ## :anchor_notfound is already defined on above
              raise syntax_error(:anchor_notfound, [val.label], val.linenum)
            end
          elsif val.is_a?(Array) || val.is_a?(Hash)
            resolve_aliases(val)
          end
        end
      else
        assert !data.is_a?(Alias)
      end
    end


    def parse_block_text(column, value)
      assert value =~ /^[>|\|]/
      value =~ /^([>|\|])([-+]?)(\d+)?\s*(.*)$/
      char = $1
      indicator = $2
      sep = char == "|" ? "\n" : " "
      margin = $3 && !$3.empty? ? $3.to_i : nil
      #text = $4.empty? ? '' :  $4 + sep
      text = $4
      s = ''
      empty = ''
      min_indent = -1
      while line = _getline()
        line =~ /^( *)(.*)/
        indent = $1.length
        if $2.empty?
          empty << "\n"
        elsif indent < column
          break
        else
          min_indent = indent if min_indent < 0 || min_indent > indent
          s << empty << line
          empty = ''
        end
      end
      s << empty if indicator == '+' && char != '>'
      s[-1] = "" if indicator == '-'
      min_indent = column + margin - 1 if margin
      if min_indent > 0
        sp = ' ' * min_indent
        s.gsub!(/^#{sp}/, '')
      end
      if char == '>'
        s.gsub!(/([^\n])\n([^\n])/, '\1 \2')
        s.gsub!(/\n(\n+)/, '\1')
        s << empty if indicator == '+'
      end
      getline() if current_line() =~ /^\s*\#/
        return create_scalar(text + s)
    end


    def parse_sequence(column, value)
      assert value =~ /^-(( +)(.*))?$/
      seq = create_sequence()  # []
      while true
        unless value =~ /^-(( +)(.*))?$/
          #* key=:sequence_noitem  msg="sequence item is expected."
          raise syntax_error(:sequence_noitem)
        end
        value2 = $3
        space  = $2
        column2 = column + 1
        linenum = current_linenum()
        #
        if !value2 || value2.empty?
          elem = parse_child(column2)
        else
          value_start_column = column2 + space.length
          elem = parse_value(column2, value2, value_start_column)
        end
        add_to_seq(seq, elem, linenum)    #seq << elem
        #
        line = current_line()
        break unless line
        line =~ /^( *)(.*)/
        indent = $1.length
        if    indent < column
          break
        elsif indent > column
          #* key=:sequence_badindent  msg="illegal indent of sequence."
          raise syntax_error(:sequence_badindent)
        end
        value = $2
      end
      return seq
    end


    def parse_mapping(column, value)
      #assert value =~ /^(:?["']?[-.\w]+["']? *):(( +)(.*))?$/         #'
      assert value =~ /^((?::?[-.\w]+\*?|'.*?'|".*?"|=|<<) *):(( +)(.*))?$/
      map = create_mapping()  # {}
      while true
        #unless value =~ /^(:?["']?[-.\w]+["']? *):(( +)(.*))?$/      #'
        unless value =~ /^((?::?[-.\w]+\*?|'.*?'|".*?"|=|<<) *):(( +)(.*))?$/
          #* key=:mapping_noitem  msg="mapping item is expected."
          raise syntax_error(:mapping_noitem)
        end
        v = $1.strip
        key = to_scalar(v)
        value2 = $4
        column2 = column + 1
        linenum = current_linenum()
        #
        if !value2 || value2.empty?
          elem = parse_child(column2)
        else
          value_start_column = column2 + $1.length + $3.length
          elem = parse_value(column2, value2, value_start_column)
        end
        case v
        when '='
          set_default(map, elem, linenum)
        when '<<'
          merge_map(map, elem, linenum)
        else
          add_to_map(map, key, elem, linenum)    # map[key] = elem
        end
        #
        line = current_line()
        break unless line
        line =~ /^( *)(.*)/
        indent = $1.length
        if    indent < column
          break
        elsif indent > column
          #* key=:mapping_badindent  msg="illegal indent of mapping."
          raise syntax_error(:mapping_badindent)
        end
        value = $2
      end
      return map
    end


    def parse_scalar(indent, value)
      data = create_scalar(to_scalar(value))
      getline()
      return data
    end


    def to_scalar(str)
      case str
      when /^"(.*)"([ \t]*\#.*$)?/    ; return $1
      when /^'(.*)'([ \t]*\#.*$)?/    ; return $1
      when /^(.*\S)[ \t]*\#/          ; str = $1
      end

      case str
      when /^-?\d+$/              ;  return str.to_i    # integer
      when /^-?\d+\.\d+$/         ;  return str.to_f    # float
      when "true", "yes", "on"    ;  return true        # true
      when "false", "no", "off"   ;  return false       # false
      when "null", "~"            ;  return nil         # nil
        #when /^"(.*)"$/             ;  return $1          # "string"
        #when /^'(.*)'$/             ;  return $1          # 'string'
      when /^:(\w+)$/             ;  return $1.intern   # :symbol
      when /^(\d\d\d\d)-(\d\d)-(\d\d)$/                 # date
        year, month, day = $1.to_i, $2.to_i, $3.to_i
        return Date.new(year, month, day)
      when /^(\d\d\d\d)-(\d\d)-(\d\d)(?:[Tt]|[ \t]+)(\d\d?):(\d\d):(\d\d)(\.\d*)?(?:Z|[ \t]*([-+]\d\d?)(?::(\d\d))?)?$/
        year, mon, mday, hour, min, sec, usec, tzone_h, tzone_m = $1, $2, $3, $4, $5, $6, $7, $8, $9
        #Time.utc(sec, min, hour, mday, mon, year, wday, yday, isdst, zone)
        #t = Time.utc(sec, min, hour, mday, mon, year, nil, nil, nil, nil)
        #Time.utc(year[, mon[, day[, hour[, min[, sec[, usec]]]]]])
        time = Time.utc(year, mon, day, hour, min, sec, usec)
        if tzone_h
          diff_sec = tzone_h.to_i * 60 * 60
          if tzone_m
            if diff_sec > 0 ; diff_sec += tzone_m.to_i * 60
            else            ; diff_sec -= tzone_m.to_i * 60
            end
          end
          p diff_sec
          time -= diff_sec
        end
        return time
      end
      return str
    end


    def assert(bool_expr)
      raise "*** assertion error" unless bool_expr
    end

  end



  ##
  ## (OBSOLETE) yaml parser
  ##
  ## this class has been obsoleted. use Kwalify::Yaml::Parser instead.
  ##
  ## ex.
  ##  # load document with YamlParser
  ##  str = ARGF.read()
  ##  parser = Kwalify::YamlParser.new(str)
  ##  document = parser.parse()
  ##
  ##  # validate document
  ##  schema = YAML.load(File.read('schema.yaml'))
  ##  validator = Kwalify::Validator.new(schema)
  ##  errors = validator.validate(document)
  ##
  ##  # print validation result
  ##  if errors && !errors.empty?
  ##    parser.set_errors_linenum(errors)
  ##    errors.sort.each do |error|
  ##      print "line %d: path %s: %s" % [error.linenum, error.path, error.message]
  ##    end
  ##  end
  ##
  class YamlParser < PlainYamlParser

    def initialize(*args)
      super
      @linenums_table = {}     # object_id -> hash or array
    end

    def parse()
      @doc = super()
      return @doc
    end

    def path_linenum(path)
      return 1 if path.empty? || path == '/'
      elems = path.split('/')
      elems.shift if path[0] == ?/    # delete empty string on head
      last_elem = elems.pop
      c = @doc   # collection
      elems.each do |elem|
        if c.is_a?(Array)
          c = c[elem.to_i]
        elsif c.is_a?(Hash)
          c = c[elem]
        else
          assert false
        end
      end
      linenums = @linenums_table[c.__id__]
      if c.is_a?(Array)
        linenum = linenums[last_elem.to_i]
      elsif c.is_a?(Hash)
        linenum = linenums[last_elem]
      end
      return linenum
    end

    def set_errors_linenum(errors)
      errors.each do |error|
        error.linenum = path_linenum(error.path)
      end
    end

    def set_error_linenums(errors)
      warn "*** Kwalify::YamlParser#set_error_linenums() is obsolete. You should use set_errors_linenum() instead."
      set_errors_linenum(errors)
    end

    protected

    def create_sequence(linenum=current_linenum())
      seq = []
      @linenums_table[seq.__id__] = []
      return seq
    end

    def add_to_seq(seq, value, linenum)
      seq << value
      @linenums_table[seq.__id__] << linenum
    end

    def set_seq_at(seq, i, value, linenum)
      seq[i] = value
      @linenums_table[seq.__id__][i] = linenum
    end

    def create_mapping(linenum=current_linenum())
      map = {}
      @linenums_table[map.__id__] = {}
      return map
    end

    def add_to_map(map, key, value, linenum)
      map[key] = value
      @linenums_table[map.__id__][key] = linenum
    end

    def set_map_with(map, key, value, linenum)
      map[key] = value
      @linenums_table[map.__id__][key] = linenum
    end

    def set_default(map, value, linenum)
      map.default = value
      @linenums_table[map.__id__][:'='] = linenum
    end

    def merge_map(map, collection, linenum)
      t = @linenums_table[map.__id__]
      list = collection.is_a?(Array) ? collection : [ collection ]
      list.each do |m|
        t2 = @linenums_table[m.__id__]
        m.each do |key, val|
          unless map.key?(key)
            map[key] = val
            t[key] = t2[key]
          end
        end
      end
    end

    def create_scalar(value, linenum=current_linenum())
      data = super(value)
      #return Scalar.new(data, linenum)
      return data
    end

  end


  ## alias of YamlParser class
  class Parser < YamlParser
    def initialize(yaml_str)
      super(yaml_str)
      #warn "*** class Kwalify::Parser is obsolete. Please use Kwalify::YamlParser instead."
    end
  end


end
