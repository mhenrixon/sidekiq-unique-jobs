###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'strscan'
require 'kwalify/errors'
require 'kwalify/util'


##
## base class for Yaml::Parser
##
class Kwalify::BaseParser


  def reset(input, filename=nil, untabify=false)
    input = Kwalify::Util.untabify(input) if untabify
    @scanner = StringScanner.new(input)
    @filename = filename
    @linenum = 1
    @column  = 1
  end
  attr_reader :filename, :linenum, :column


  def scan(regexp)
    ret = @scanner.scan(regexp)
    return nil if ret.nil?
    _set_column_and_linenum(ret)
    return ret
  end


  def _set_column_and_linenum(s)
    pos = s.rindex(?\n)
    if pos
      @column = s.length - pos
      @linenum += s.count("\n")
    else
      @column += s.length
    end
  end


  def match?(regexp)
    return @scanner.match?(regexp)
  end


  def group(n)
    return @scanner[n]
  end


  def eos?
    return @scanner.eos?
  end


  def peep(n=1)
    return @scanner.peep(n)
  end


  def _getch
    ch = @scanner.getch()
    if ch == "\n"
      @linenum += 1
      @column = 0
    else
      @column += 1
    end
    return ch
  end


  CHAR_TABLE = { "\""=>"\"", "\\"=>"\\", "n"=>"\n", "r"=>"\r", "t"=>"\t", "b"=>"\b" }

  def scan_string
    ch = _getch()
    ch == '"' || ch == "'" or raise "assertion error"
    endch = ch
    s = ''
    while !(ch = _getch()).nil? && ch != endch
      if ch != '\\'
        s << ch
      elsif (ch = _getch()).nil?
        raise _syntax_error("%s: string is not closed." % (endch == '"' ? "'\"'" : '"\'"'))
      elsif endch == '"'
        if CHAR_TABLE.key?(ch)
          s << CHAR_TABLE[ch]
        elsif ch == 'u'
          ch2 = scan(/(?:[0-9a-f][0-9a-f]){1,4}/)
          unless ch2
            raise _syntax_error("\\x: invalid unicode format.")
          end
          s << [ch2.hex].pack('U*')
        elsif ch == 'x'
          ch2 = scan(/[0-9a-zA-Z][0-9a-zA-Z]/)
          unless ch2
            raise _syntax_error("\\x: invalid binary format.")
          end
          s << [ch2].pack('H2')
        else
          s << "\\" << ch
        end
      elsif endch == "'"
        ch == '\'' || ch == '\\' ? s << ch : s << '\\' << ch
      else
        raise "unreachable"
      end
    end
    #_getch()
    return s
  end


  def _syntax_error(message, path=nil, linenum=@linenum, column=@column)
    #message = _build_message(message_key)
    return _error(Kwalify::SyntaxError, message.to_s, path, linenum, column)
  end
  protected :_syntax_error


end
