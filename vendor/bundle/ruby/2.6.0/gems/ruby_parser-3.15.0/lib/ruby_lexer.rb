# frozen_string_literal: true
# encoding: UTF-8

$DEBUG = true if ENV["DEBUG"]

class RubyLexer
  # :stopdoc:
  EOF = :eof_haha!

  ESCAPES = {
    "a"    => "\007",
    "b"    => "\010",
    "e"    => "\033",
    "f"    => "\f",
    "n"    => "\n",
    "r"    => "\r",
    "s"    => " ",
    "t"    => "\t",
    "v"    => "\13",
    "\\"   => '\\',
    "\n"   => "",
    "C-\?" => 127.chr,
    "c\?"  => 127.chr,
  }

  HAS_ENC = "".respond_to? :encoding

  TOKENS = {
    "!"   => :tBANG,
    "!="  => :tNEQ,
    # "!@"  => :tUBANG,
    "!~"  => :tNMATCH,
    ","   => :tCOMMA,
    ".."  => :tDOT2,
    "..." => :tDOT3,
    "="   => :tEQL,
    "=="  => :tEQ,
    "===" => :tEQQ,
    "=>"  => :tASSOC,
    "=~"  => :tMATCH,
    "->"  => :tLAMBDA,
  }

  @@regexp_cache = Hash.new { |h, k| h[k] = Regexp.new(Regexp.escape(k)) }
  @@regexp_cache[nil] = nil

  if $DEBUG then
    attr_reader :lex_state

    def lex_state= o
      return if @lex_state == o
      raise ArgumentError, "bad state: %p" % [o] unless State === o

      warn "lex_state: %p -> %p" % [lex_state, o]

      @lex_state = o
    end
  end

  # :startdoc:

  attr_accessor :lex_state unless $DEBUG

  attr_accessor :lineno # we're bypassing oedipus' lineno handling.
  attr_accessor :brace_nest
  attr_accessor :cmdarg
  attr_accessor :command_start
  attr_accessor :cmd_state # temporary--ivar to avoid passing everywhere
  attr_accessor :last_state
  attr_accessor :cond
  attr_accessor :extra_lineno

  ##
  # Additional context surrounding tokens that both the lexer and
  # grammar use.

  attr_accessor :lex_strterm
  attr_accessor :lpar_beg
  attr_accessor :paren_nest
  attr_accessor :parser # HACK for very end of lexer... *sigh*
  attr_accessor :space_seen
  attr_accessor :string_buffer
  attr_accessor :string_nest

  # Last token read via next_token.
  attr_accessor :token

  attr_writer :comments

  def initialize _ = nil
    @lex_state = nil # remove one warning under $DEBUG
    self.lex_state = EXPR_NONE

    self.cond   = RubyParserStuff::StackState.new(:cond, $DEBUG)
    self.cmdarg = RubyParserStuff::StackState.new(:cmdarg, $DEBUG)

    reset
  end

  def arg_ambiguous
    self.warning "Ambiguous first argument. make sure."
  end

  def arg_state
    is_after_operator? ? EXPR_ARG : EXPR_BEG
  end

  def beginning_of_line?
    ss.bol?
  end

  alias bol? beginning_of_line? # to make .rex file more readable

  def check re
    ss.check re
  end

  def comments # TODO: remove this... maybe comment_string + attr_accessor
    c = @comments.join
    @comments.clear
    c
  end

  def eat_whitespace
    r = scan(/\s+/)
    self.extra_lineno += r.count("\n") if r
    r
  end

  def end_of_stream?
    ss.eos?
  end

  def expr_dot?
    lex_state =~ EXPR_DOT
  end

  def expr_fname? # REFACTOR
    lex_state =~ EXPR_FNAME
  end

  def expr_result token, text
    cond.push false
    cmdarg.push false
    result EXPR_BEG, token, text
  end

  def fixup_lineno extra = 0
    self.lineno += self.extra_lineno + extra
    self.extra_lineno = 0
  end

  def heredoc here # TODO: rewrite / remove
    _, eos, func, last_line = here

    indent         = func =~ STR_FUNC_INDENT ? "[ \t]*" : nil
    expand         = func =~ STR_FUNC_EXPAND
    eol            = last_line && last_line.end_with?("\r\n") ? "\r\n" : "\n"
    eos_re         = /#{indent}#{Regexp.escape eos}(\r*\n|\z)/
    err_msg        = "can't match #{eos_re.inspect} anywhere in "

    rb_compile_error err_msg if end_of_stream?

    if beginning_of_line? && scan(eos_re) then
      self.lineno += 1
      ss.unread_many last_line # TODO: figure out how to remove this
      return :tSTRING_END, [eos, func] # TODO: calculate squiggle width at lex?
    end

    self.string_buffer = []

    if expand then
      case
      when scan(/#(?=\$(-.|[a-zA-Z_0-9~\*\$\?!@\/\\;,\.=:<>\"\&\`\'+]))/) then
        # TODO: !ISASCII
        # ?! see parser_peek_variable_name
        return :tSTRING_DVAR, matched
      when scan(/#(?=\@\@?[a-zA-Z_])/) then
        # TODO: !ISASCII
        return :tSTRING_DVAR, matched
      when scan(/#[{]/) then
        self.command_start = true
        return :tSTRING_DBEG, matched
      when scan(/#/) then
        string_buffer << "#"
      end

      begin
        c = tokadd_string func, eol, nil

        rb_compile_error err_msg if
          c == RubyLexer::EOF

        if c != eol then
          return :tSTRING_CONTENT, string_buffer.join
        else
          string_buffer << scan(/\n/)
        end

        rb_compile_error err_msg if end_of_stream?
      end until check(eos_re)
    else
      until check(eos_re) do
        string_buffer << scan(/.*(\n|\z)/)
        rb_compile_error err_msg if end_of_stream?
      end
    end

    self.lex_strterm = [:heredoc, eos, func, last_line]

    string_content = begin
                       s = string_buffer.join
                       s.b.force_encoding Encoding::UTF_8
                     end

    return :tSTRING_CONTENT, string_content
  end

  def heredoc_identifier # TODO: remove / rewrite
    term, func = nil, STR_FUNC_BORING
    self.string_buffer = []

    heredoc_indent_mods = "-"
    heredoc_indent_mods += '\~' if ruby23plus?

    case
    when scan(/([#{heredoc_indent_mods}]?)([\'\"\`])(.*?)\2/) then
      term = ss[2]
      func |= STR_FUNC_INDENT unless ss[1].empty? # TODO: this seems wrong
      func |= STR_FUNC_ICNTNT if ss[1] == "~"
      func |= case term
              when "\'" then
                STR_SQUOTE
              when '"' then
                STR_DQUOTE
              else
                STR_XQUOTE
              end
      string_buffer << ss[3]
    when scan(/[#{heredoc_indent_mods}]?([\'\"\`])(?!\1*\Z)/) then
      rb_compile_error "unterminated here document identifier"
    when scan(/([#{heredoc_indent_mods}]?)(#{IDENT_CHAR}+)/) then
      term = '"'
      func |= STR_DQUOTE
      unless ss[1].empty? then
        func |= STR_FUNC_INDENT
        func |= STR_FUNC_ICNTNT if ss[1] == "~"
      end
      string_buffer << ss[2]
    else
      return nil
    end

    if scan(/.*\n/) then
      # TODO: think about storing off the char range instead
      line = matched
    else
      line = nil
    end

    self.lex_strterm = [:heredoc, string_buffer.join, func, line]

    if term == "`" then
      result nil, :tXSTRING_BEG, "`"
    else
      result nil, :tSTRING_BEG, "\""
    end
  end

  def in_fname? # REFACTOR
    lex_state =~ EXPR_FNAME
  end

  def int_with_base base
    rb_compile_error "Invalid numeric format" if matched =~ /__/

    text = matched
    case
    when text.end_with?("ri")
      return result(EXPR_NUM, :tIMAGINARY, Complex(0, Rational(text.chop.chop.to_i(base))))
    when text.end_with?("r")
      return result(EXPR_NUM, :tRATIONAL, Rational(text.chop.to_i(base)))
    when text.end_with?("i")
      return result(EXPR_NUM, :tIMAGINARY, Complex(0, text.chop.to_i(base)))
    else
      return result(EXPR_NUM, :tINTEGER, text.to_i(base))
    end
  end

  def is_after_operator?
    lex_state =~ EXPR_FNAME|EXPR_DOT
  end

  def is_arg?
    lex_state =~ EXPR_ARG_ANY
  end

  def is_beg?
    lex_state =~ EXPR_BEG_ANY || lex_state == EXPR_LAB # yes, == EXPR_LAB
  end

  def is_end?
    lex_state =~ EXPR_END_ANY
  end

  def is_label_possible?
    (lex_state =~ EXPR_LABEL|EXPR_ENDFN && !cmd_state) || is_arg?
  end

  def is_label_suffix?
    check(/:(?!:)/)
  end

  def is_space_arg? c = "x"
    is_arg? and space_seen and c !~ /\s/
  end

  def lambda_beginning?
    lpar_beg && lpar_beg == paren_nest
  end

  def is_local_id id
    # maybe just make this false for now
    self.parser.env[id.to_sym] == :lvar # HACK: this isn't remotely right
  end

  def lvar_defined? id
    # TODO: (dyna_in_block? && dvar_defined?(id)) || local_id?(id)
    self.parser.env[id.to_sym] == :lvar
  end

  def matched
    ss.matched
  end

  def not_end?
    not is_end?
  end

  def parse_quote # TODO: remove / rewrite
    beg, nnd, short_hand, c = nil, nil, false, nil

    if scan(/[a-z0-9]{1,2}/i) then # Long-hand (e.g. %Q{}).
      rb_compile_error "unknown type of %string" if ss.matched_size == 2
      c, beg, short_hand = matched, getch, false
    else                               # Short-hand (e.g. %{, %., %!, etc)
      c, beg, short_hand = "Q", getch, true
    end

    if end_of_stream? or c == RubyLexer::EOF or beg == RubyLexer::EOF then
      rb_compile_error "unterminated quoted string meets end of file"
    end

    # Figure nnd-char.  "\0" is special to indicate beg=nnd and that no nesting?
    nnd = { "(" => ")", "[" => "]", "{" => "}", "<" => ">" }[beg]
    nnd, beg = beg, "\0" if nnd.nil?

    token_type, text = nil, "%#{c}#{beg}"
    token_type, string_type = case c
                              when "Q" then
                                ch = short_hand ? nnd : c + beg
                                text = "%#{ch}"
                                [:tSTRING_BEG,   STR_DQUOTE]
                              when "q" then
                                [:tSTRING_BEG,   STR_SQUOTE]
                              when "W" then
                                eat_whitespace
                                [:tWORDS_BEG,    STR_DQUOTE | STR_FUNC_QWORDS]
                              when "w" then
                                eat_whitespace
                                [:tQWORDS_BEG,   STR_SQUOTE | STR_FUNC_QWORDS]
                              when "x" then
                                [:tXSTRING_BEG,  STR_XQUOTE]
                              when "r" then
                                [:tREGEXP_BEG,   STR_REGEXP]
                              when "s" then
                                self.lex_state = EXPR_FNAME
                                [:tSYMBEG,       STR_SSYM]
                              when "I" then
                                eat_whitespace
                                [:tSYMBOLS_BEG, STR_DQUOTE | STR_FUNC_QWORDS]
                              when "i" then
                                eat_whitespace
                                [:tQSYMBOLS_BEG, STR_SQUOTE | STR_FUNC_QWORDS]
                              end

    rb_compile_error "Bad %string type. Expected [QqWwIixrs], found '#{c}'." if
      token_type.nil?

    raise "huh" unless string_type

    string string_type, nnd, beg

    return token_type, text
  end

  def parse_string quote # TODO: rewrite / remove
    _, string_type, term, open = quote

    space = false # FIX: remove these
    func = string_type
    paren = open
    term_re = @@regexp_cache[term]

    qwords = func =~ STR_FUNC_QWORDS
    regexp = func =~ STR_FUNC_REGEXP
    expand = func =~ STR_FUNC_EXPAND

    unless func then # nil'ed from qwords below. *sigh*
      return :tSTRING_END, nil
    end

    space = true if qwords and eat_whitespace

    if self.string_nest == 0 && scan(/#{term_re}/) then
      if qwords then
        quote[1] = nil
        return :tSPACE, nil
      elsif regexp then
        return :tREGEXP_END, self.regx_options
      else
        return :tSTRING_END, term
      end
    end

    return :tSPACE, nil if space

    self.string_buffer = []

    if expand
      case
      when scan(/#(?=\$(-.|[a-zA-Z_0-9~\*\$\?!@\/\\;,\.=:<>\"\&\`\'+]))/) then
        # TODO: !ISASCII
        # ?! see parser_peek_variable_name
        return :tSTRING_DVAR, nil
      when scan(/#(?=\@\@?[a-zA-Z_])/) then
        # TODO: !ISASCII
        return :tSTRING_DVAR, nil
      when scan(/#[{]/) then
        self.command_start = true
        return :tSTRING_DBEG, nil
      when scan(/#/) then
        string_buffer << "#"
      end
    end

    if tokadd_string(func, term, paren) == RubyLexer::EOF then
      if func =~ STR_FUNC_REGEXP then
        rb_compile_error "unterminated regexp meets end of file"
      else
        rb_compile_error "unterminated string meets end of file"
      end
    end

    return :tSTRING_CONTENT, string_buffer.join
  end

  def possibly_escape_string text, check
    content = match[1]

    if text =~ check then
      content.gsub(ESC) { unescape $1 }
    else
      content.gsub(/\\\\/, "\\").gsub(/\\\'/, "'")
    end
  end

  def process_amper text
    token = if is_arg? && space_seen && !check(/\s/) then
               warning("`&' interpreted as argument prefix")
               :tAMPER
             elsif lex_state =~ EXPR_BEG|EXPR_MID then
               :tAMPER
             else
               :tAMPER2
             end

    return result(:arg_state, token, "&")
  end

  def process_backref text
    token = ss[1].to_sym
    # TODO: can't do lineno hack w/ symbol
    result EXPR_END, :tBACK_REF, token
  end

  def process_begin text
    @comments << matched

    unless scan(/.*?\n=end( |\t|\f)*[^\n]*(\n|\z)/m) then
      @comments.clear
      rb_compile_error("embedded document meets end of file")
    end

    @comments << matched
    self.lineno += matched.count("\n")

    nil # TODO
  end

  def process_brace_close text
    case matched
    when "}" then
      self.brace_nest -= 1
      return :tSTRING_DEND, matched if brace_nest < 0
    end

    # matching compare/parse26.y:8099
    cond.pop
    cmdarg.pop

    case matched
    when "}" then
      self.lex_state   = ruby24minus? ? EXPR_ENDARG : EXPR_END
      return :tRCURLY, matched
    when "]" then
      self.paren_nest -= 1
      self.lex_state   = ruby24minus? ? EXPR_ENDARG : EXPR_END
      return :tRBRACK, matched
    when ")" then
      self.paren_nest -= 1
      self.lex_state   = EXPR_ENDFN
      return :tRPAREN, matched
    else
      raise "Unknown bracing: #{matched.inspect}"
    end
  end

  def process_brace_open text
    # matching compare/parse23.y:8694
    self.brace_nest += 1

    if lambda_beginning? then
      self.lpar_beg = nil
      self.paren_nest -= 1 # close arg list when lambda opens body

      return expr_result(:tLAMBEG, "{")
    end

    token = case
            when lex_state =~ EXPR_LABELED then
              :tLBRACE     # hash
            when lex_state =~ EXPR_ARG_ANY|EXPR_END|EXPR_ENDFN then
              :tLCURLY     # block (primary) "{" in parse.y
            when lex_state =~ EXPR_ENDARG then
              :tLBRACE_ARG # block (expr)
            else
              :tLBRACE     # hash
            end

    state = token == :tLBRACE_ARG ? EXPR_BEG : EXPR_PAR
    self.command_start = true if token != :tLBRACE

    cond.push false
    cmdarg.push false
    result state, token, text
  end

  def process_colon1 text
    # ?: / then / when
    if is_end? || check(/\s/) then
      return result EXPR_BEG, :tCOLON, text
    end

    case
    when scan(/\'/) then
      string STR_SSYM
    when scan(/\"/) then
      string STR_DSYM
    end

    result EXPR_FNAME, :tSYMBEG, text
  end

  def process_colon2 text
    if is_beg? || lex_state =~ EXPR_CLASS || is_space_arg? then
      result EXPR_BEG, :tCOLON3, text
    else
      result EXPR_DOT, :tCOLON2, text
    end
  end

  def process_float text
    rb_compile_error "Invalid numeric format" if text =~ /__/

    case
    when text.end_with?("ri")
      return result EXPR_NUM, :tIMAGINARY, Complex(0, Rational(text.chop.chop))
    when text.end_with?("i")
      return result EXPR_NUM, :tIMAGINARY, Complex(0, text.chop.to_f)
    when text.end_with?("r")
      return result EXPR_NUM, :tRATIONAL,  Rational(text.chop)
    else
      return result EXPR_NUM, :tFLOAT, text.to_f
    end
  end

  def process_gvar text
    text.lineno = self.lineno
    result EXPR_END, :tGVAR, text
  end

  def process_gvar_oddity text
    return result EXPR_END, "$", "$" if text == "$" # TODO: wtf is this?
    rb_compile_error "#{text.inspect} is not allowed as a global variable name"
  end

  def process_ivar text
    tok_id = text =~ /^@@/ ? :tCVAR : :tIVAR
    text.lineno = self.lineno
    result EXPR_END, tok_id, text
  end

  def process_label text
    symbol = possibly_escape_string text, /^\"/

    result EXPR_LAB, :tLABEL, [symbol, self.lineno]
  end

  def process_label_or_string text
    if @was_label && text =~ /:\Z/ then
      @was_label = nil
      return process_label text
    elsif text =~ /:\Z/ then
      ss.pos -= 1 # put back ":"
      text = text[0..-2]
    end

    result EXPR_END, :tSTRING, text[1..-2].gsub(/\\\\/, "\\").gsub(/\\\'/, "\'")
  end

  def process_lchevron text
    if (lex_state !~ EXPR_DOT|EXPR_CLASS &&
        !is_end? &&
        (!is_arg? || lex_state =~ EXPR_LABELED || space_seen)) then
      tok = self.heredoc_identifier
      return tok if tok
    end

    if is_after_operator? then
      self.lex_state = EXPR_ARG
    else
      self.command_start = true if lex_state =~ EXPR_CLASS
      self.lex_state = EXPR_BEG
    end

    return result(lex_state, :tLSHFT, "\<\<")
  end

  def process_newline_or_comment text
    c = matched
    hit = false

    if c == "#" then
      ss.pos -= 1

      # TODO: handle magic comments
      while scan(/\s*\#.*(\n+|\z)/) do
        hit = true
        self.lineno += matched.lines.to_a.size
        @comments << matched.gsub(/^ +#/, "#").gsub(/^ +$/, "")
      end

      return nil if end_of_stream?
    end

    self.lineno += 1 unless hit

    # Replace a string of newlines with a single one
    self.lineno += matched.lines.to_a.size if scan(/\n+/)

    c = (lex_state =~ EXPR_BEG|EXPR_CLASS|EXPR_FNAME|EXPR_DOT &&
         lex_state !~ EXPR_LABELED)
    # TODO: figure out what token_seen is for
    if c || self.lex_state == EXPR_LAB then # yes, == EXPR_LAB
      # ignore if !fallthrough?
      if !c && parser.in_kwarg then
        # normal newline
        self.command_start = true
        return result EXPR_BEG, :tNL, nil
      else
        return # skip
      end
    end

    if scan(/([\ \t\r\f\v]*)(\.|&)/) then
      self.space_seen = true unless ss[1].empty?

      ss.pos -= 1
      return unless check(/\.\./)
    end

    self.command_start = true

    return result(EXPR_BEG, :tNL, nil)
  end

  def process_nthref text
    # TODO: can't do lineno hack w/ number
    result EXPR_END, :tNTH_REF, ss[1].to_i
  end

  def process_paren text
    token = if is_beg? then
              :tLPAREN
            elsif !space_seen then
              # foo( ... ) => method call, no ambiguity
              :tLPAREN2
            elsif is_space_arg? then
              :tLPAREN_ARG
            elsif lex_state =~ EXPR_ENDFN && !lambda_beginning? then
              # TODO:
              # warn("parentheses after method name is interpreted as " \
              #      "an argument list, not a decomposed argument")
              :tLPAREN2
            else
              :tLPAREN2 # plain "(" in parse.y
            end

    self.paren_nest += 1

    cond.push false
    cmdarg.push false
    result EXPR_PAR, token, text
  end

  def process_percent text
    return parse_quote if is_beg?

    return result EXPR_BEG, :tOP_ASGN, "%" if scan(/\=/)

    return parse_quote if is_space_arg?(check(/\s/)) || (lex_state =~ EXPR_FITEM && check(/s/))

    return result :arg_state, :tPERCENT, "%"
  end

  def process_plus_minus text
    sign = matched
    utype, type = if sign == "+" then
                    [:tUPLUS, :tPLUS]
                  else
                    [:tUMINUS, :tMINUS]
                  end

    if is_after_operator? then
      if scan(/@/) then
        return result(EXPR_ARG, utype, "#{sign}@")
      else
        return result(EXPR_ARG, type, sign)
      end
    end

    return result(EXPR_BEG, :tOP_ASGN, sign) if scan(/\=/)

    if is_beg? || (is_arg? && space_seen && !check(/\s/)) then
      arg_ambiguous if is_arg?

      if check(/\d/) then
        return nil if utype == :tUPLUS
        return result EXPR_BEG, :tUMINUS_NUM, sign
      end

      return result EXPR_BEG, utype, sign
    end

    result EXPR_BEG, type, sign
  end

  def process_questionmark text
    if is_end? then
      return result EXPR_BEG, :tEH, "?"
    end

    if end_of_stream? then
      rb_compile_error "incomplete character syntax: parsed #{text.inspect}"
    end

    if check(/\s|\v/) then
      unless is_arg? then
        c2 = { " " => "s",
              "\n" => "n",
              "\t" => "t",
              "\v" => "v",
              "\r" => "r",
              "\f" => "f" }[matched]

        if c2 then
          warning("invalid character syntax; use ?\\" + c2)
        end
      end

      # ternary
      return result EXPR_BEG, :tEH, "?"
    elsif check(/\w(?=\w)/) then # ternary, also
      return result EXPR_BEG, :tEH, "?"
    end

    c = if scan(/\\/) then
          self.read_escape
        else
          getch
        end

    result EXPR_END, :tSTRING, c
  end

  def process_simple_string text
    replacement = text[1..-2].gsub(ESC) {
      unescape($1).b.force_encoding Encoding::UTF_8
    }

    replacement = replacement.b unless replacement.valid_encoding?

    result EXPR_END, :tSTRING, replacement
  end

  def process_slash text
    if is_beg? then
      string STR_REGEXP

      return result(nil, :tREGEXP_BEG, "/")
    end

    if scan(/\=/) then
      return result(EXPR_BEG, :tOP_ASGN, "/")
    end

    if is_arg? && space_seen then
      unless scan(/\s/) then
        arg_ambiguous
        string STR_REGEXP, "/"
        return result(nil, :tREGEXP_BEG, "/")
      end
    end

    return result(:arg_state, :tDIVIDE, "/")
  end

  def process_square_bracket text
    self.paren_nest += 1

    token = nil

    if is_after_operator? then
      case
      when scan(/\]\=/) then
        self.paren_nest -= 1 # HACK? I dunno, or bug in MRI
        return result EXPR_ARG, :tASET, "[]="
      when scan(/\]/) then
        self.paren_nest -= 1 # HACK? I dunno, or bug in MRI
        return result EXPR_ARG, :tAREF, "[]"
      else
        rb_compile_error "unexpected '['"
      end
    elsif is_beg? then
      token = :tLBRACK
    elsif is_arg? && (space_seen || lex_state =~ EXPR_LABELED) then
      token = :tLBRACK
    else
      token = :tLBRACK2
    end

    cond.push false
    cmdarg.push false
    result EXPR_PAR, token, text
  end

  def process_string # TODO: rewrite / remove
    # matches top of parser_yylex in compare/parse23.y:8113
    token = if lex_strterm[0] == :heredoc then
              self.heredoc lex_strterm
            else
              self.parse_string lex_strterm
            end

    token_type, c = token

    # matches parser_string_term from 2.3, but way off from 2.5
    if ruby22plus? && token_type == :tSTRING_END && ["'", '"'].include?(c) then
      if ((lex_state =~ EXPR_BEG|EXPR_ENDFN &&
           !cond.is_in_state) || is_arg?) &&
          is_label_suffix? then
        scan(/:/)
        token_type = token[0] = :tLABEL_END
      end
    end

    if [:tSTRING_END, :tREGEXP_END, :tLABEL_END].include? token_type then
      self.lex_strterm = nil
      self.lex_state   = (token_type == :tLABEL_END) ? EXPR_PAR : EXPR_LIT
    end

    return token
  end

  def process_symbol text
    symbol = possibly_escape_string text, /^:\"/ # stupid emacs

    result EXPR_LIT, :tSYMBOL, symbol
  end

  def process_token text
    # matching: parse_ident in compare/parse23.y:7989
    # TODO: make this always return [token, lineno]
    # FIX: remove: self.last_state = lex_state

    token = self.token = text
    token << matched if scan(/[\!\?](?!=)/)

    tok_id =
      case
      when token =~ /[!?]$/ then
        :tFID
      when lex_state =~ EXPR_FNAME && scan(/=(?:(?![~>=])|(?==>))/) then
        # ident=, not =~ => == or followed by =>
        # TODO test lexing of a=>b vs a==>b
        token << matched
        :tIDENTIFIER
      when token =~ /^[A-Z]/ then
        :tCONSTANT
      else
        :tIDENTIFIER
      end

    if is_label_possible? and is_label_suffix? then
      scan(/:/)
      # TODO: propagate the lineno to ALL results
      return result EXPR_LAB, :tLABEL, [token, self.lineno]
    end

    # TODO: mb == ENC_CODERANGE_7BIT && lex_state !~ EXPR_DOT
    if lex_state !~ EXPR_DOT then
      # See if it is a reserved word.
      keyword = RubyParserStuff::Keyword.keyword token

      return process_token_keyword keyword if keyword
    end

    # matching: compare/parse23.y:8079
    state = if is_beg? or is_arg? or lex_state =~ EXPR_DOT then
              cmd_state ? EXPR_CMDARG : EXPR_ARG
            elsif lex_state =~ EXPR_FNAME then
              EXPR_ENDFN
            else
              EXPR_END
            end

    tok_id = :tIDENTIFIER if tok_id == :tCONSTANT && is_local_id(token)

    if last_state !~ EXPR_DOT|EXPR_FNAME and
        (tok_id == :tIDENTIFIER) and # not EXPR_FNAME, not attrasgn
        lvar_defined?(token) then
      state = EXPR_END|EXPR_LABEL
    end

    token.lineno = self.lineno # yes, on a string. I know... I know...

    return result(state, tok_id, token)
  end

  def process_token_keyword keyword
    # matching MIDDLE of parse_ident in compare/parse23.y:8046
    state = lex_state
    self.lex_state = keyword.state

    value = [token, self.lineno]

    return result(lex_state, keyword.id0, value) if state =~ EXPR_FNAME

    self.command_start = true if lex_state =~ EXPR_BEG

    case
    when keyword.id0 == :kDO then # parse26.y line 7591
      case
      when lambda_beginning? then
        self.lpar_beg = nil # lambda_beginning? == FALSE in the body of "-> do ... end"
        self.paren_nest -= 1 # TODO: question this?
        result lex_state, :kDO_LAMBDA, value
      when cond.is_in_state then
        result lex_state, :kDO_COND, value
      when cmdarg.is_in_state && state != EXPR_CMDARG then
        result lex_state, :kDO_BLOCK, value
      else
        result lex_state, :kDO, value
      end
    when state =~ EXPR_PAD then
      result lex_state, keyword.id0, value
    when keyword.id0 != keyword.id1 then
      result EXPR_PAR, keyword.id1, value
    else
      result lex_state, keyword.id1, value
    end
  end

  def process_underscore text
    ss.unscan # put back "_"

    if beginning_of_line? && scan(/\__END__(\r?\n|\Z)/) then
      [RubyLexer::EOF, RubyLexer::EOF]
    elsif scan(/#{IDENT_CHAR}+/) then
      process_token matched
    end
  end

  def rb_compile_error msg
    msg += ". near line #{self.lineno}: #{ss.rest[/^.*/].inspect}"
    raise RubyParser::SyntaxError, msg
  end

  def read_escape # TODO: remove / rewrite
    case
    when scan(/\\/) then                  # Backslash
      '\\'
    when scan(/n/) then                   # newline
      self.extra_lineno -= 1
      "\n"
    when scan(/t/) then                   # horizontal tab
      "\t"
    when scan(/r/) then                   # carriage-return
      "\r"
    when scan(/f/) then                   # form-feed
      "\f"
    when scan(/v/) then                   # vertical tab
      "\13"
    when scan(/a/) then                   # alarm(bell)
      "\007"
    when scan(/e/) then                   # escape
      "\033"
    when scan(/b/) then                   # backspace
      "\010"
    when scan(/s/) then                   # space
      " "
    when scan(/[0-7]{1,3}/) then          # octal constant
      (matched.to_i(8) & 0xFF).chr.force_encoding Encoding::UTF_8
    when scan(/x([0-9a-fA-F]{1,2})/) then # hex constant
      # TODO: force encode everything to UTF-8?
      ss[1].to_i(16).chr.force_encoding Encoding::UTF_8
    when check(/M-\\./) then
      scan(/M-\\/) # eat it
      c = self.read_escape
      c[0] = (c[0].ord | 0x80).chr
      c
    when scan(/M-(.)/) then
      c = ss[1]
      c[0] = (c[0].ord | 0x80).chr
      c
    when check(/(C-|c)\\[\\MCc]/) then
      scan(/(C-|c)\\/) # eat it
      c = self.read_escape
      c[0] = (c[0].ord & 0x9f).chr
      c
    when check(/(C-|c)\\(?!u|\\)/) then
      scan(/(C-|c)\\/) # eat it
      c = read_escape
      c[0] = (c[0].ord & 0x9f).chr
      c
    when scan(/C-\?|c\?/) then
      127.chr
    when scan(/(C-|c)(.)/) then
      c = ss[2]
      c[0] = (c[0].ord & 0x9f).chr
      c
    when scan(/^[89]/i) then # bad octal or hex... MRI ignores them :(
      matched
    when scan(/u(\h{4})/) then
      [ss[1].to_i(16)].pack("U")
    when scan(/u(\h{1,3})/) then
      rb_compile_error "Invalid escape character syntax"
    when scan(/u\{(\h+(?:\s+\h+)*)\}/) then
      ss[1].split.map { |s| s.to_i(16) }.pack("U*")
    when scan(/[McCx0-9]/) || end_of_stream? then
      rb_compile_error("Invalid escape character syntax")
    else
      getch
    end.dup
  end

  def getch
    c = ss.getch
    c = ss.getch if c == "\r" && ss.peek(1) == "\n"
    c
  end

  def regx_options # TODO: rewrite / remove
    good, bad = [], []

    if scan(/[a-z]+/) then
      good, bad = matched.split(//).partition { |s| s =~ /^[ixmonesu]$/ }
    end

    unless bad.empty? then
      rb_compile_error("unknown regexp option%s - %s" %
                       [(bad.size > 1 ? "s" : ""), bad.join.inspect])
    end

    return good.join
  end

  def reset
    self.brace_nest    = 0
    self.command_start = true
    self.comments      = []
    self.lex_state     = EXPR_NONE
    self.lex_strterm   = nil
    self.lineno        = 1
    self.lpar_beg      = nil
    self.paren_nest    = 0
    self.space_seen    = false
    self.string_nest   = 0
    self.token         = nil
    self.extra_lineno  = 0

    self.cond.reset
    self.cmdarg.reset
  end

  def result new_state, token, text # :nodoc:
    new_state = self.arg_state if new_state == :arg_state
    self.lex_state = new_state if new_state
    [token, text]
  end

  def ruby22_label?
    ruby22plus? and is_label_possible?
  end

  def ruby22plus?
    parser.class.version >= 22
  end

  def ruby23plus?
    parser.class.version >= 23
  end

  def ruby24minus?
    parser.class.version <= 24
  end

  def scan re
    ss.scan re
  end

  def scanner_class # TODO: design this out of oedipus_lex. or something.
    RPStringScanner
  end

  def space_vs_beginning space_type, beg_type, fallback
    if is_space_arg? check(/./m) then
      warning "`**' interpreted as argument prefix"
      space_type
    elsif is_beg? then
      beg_type
    else
      # TODO: warn_balanced("**", "argument prefix");
      fallback
    end
  end

  def string type, beg = matched, nnd = "\0"
    self.lex_strterm = [:strterm, type, beg, nnd]
  end

  def tokadd_escape term # TODO: rewrite / remove
    case
    when scan(/\\\n/) then
      # just ignore
    when scan(/\\([0-7]{1,3}|x[0-9a-fA-F]{1,2})/) then
      self.string_buffer << matched
    when scan(/\\([MC]-|c)(?=\\)/) then
      self.string_buffer << matched
      self.tokadd_escape term
    when scan(/\\([MC]-|c)(.)/) then
      self.string_buffer << matched
    when scan(/\\[McCx]/) then
      rb_compile_error "Invalid escape character syntax"
    when scan(/\\(.)/m) then
      chr = ss[1]
      prev = self.string_buffer.last
      if term == chr && prev && prev.end_with?("(?") then
        self.string_buffer << chr
      elsif term == chr || chr.ascii_only? then
        self.string_buffer << matched # dunno why we keep them for ascii
      else
        self.string_buffer << chr # HACK? this is such a rat's nest
      end
    else
      rb_compile_error "Invalid escape character syntax"
    end
  end

  def tokadd_string(func, term, paren) # TODO: rewrite / remove
    qwords = func =~ STR_FUNC_QWORDS
    escape = func =~ STR_FUNC_ESCAPE
    expand = func =~ STR_FUNC_EXPAND
    regexp = func =~ STR_FUNC_REGEXP
    symbol = func =~ STR_FUNC_SYMBOL

    paren_re = @@regexp_cache[paren]
    term_re  = if term == "\n"
                 /#{Regexp.escape "\r"}?#{Regexp.escape "\n"}/
               else
                 @@regexp_cache[term]
               end

    until end_of_stream? do
      c = nil
      handled = true

      case
      when scan(term_re) then
        if self.string_nest == 0 then
          ss.pos -= 1
          break
        else
          self.string_nest -= 1
        end
      when paren_re && scan(paren_re) then
        self.string_nest += 1
      when expand && scan(/#(?=[\$\@\{])/) then # TODO: this seems wrong
        ss.pos -= 1
        break
      when qwords && scan(/\s/) then
        ss.pos -= 1
        break
      when expand && scan(/#(?!\n)/) then
        # do nothing
      when check(/\\/) then
        case
        when qwords && scan(/\\\n/) then
          string_buffer << "\n"
          next
        when qwords && scan(/\\\s/) then
          c = " "
        when expand && scan(/\\\n/) then
          next
        when regexp && check(/\\/) then
          self.tokadd_escape term
          next
        when expand && scan(/\\/) then
          c = self.read_escape
        when scan(/\\\n/) then
          # do nothing
        when scan(/\\\\/) then
          string_buffer << '\\' if escape
          c = '\\'
        when scan(/\\/) then
          unless scan(term_re) || paren.nil? || scan(paren_re) then
            string_buffer << "\\"
          end
        else
          handled = false
        end # inner /\\/ case
      else
        handled = false
      end # top case

      unless handled then
        t = if term == "\n"
              Regexp.escape "\r\n"
            else
              Regexp.escape term
            end
        x = Regexp.escape paren if paren && paren != "\000"
        re = if qwords then
               /[^#{t}#{x}\#\\\s]+|./ # |. to pick up whatever
             else
               /[^#{t}#{x}\#\\]+|./
             end

        scan re
        c = matched

        rb_compile_error "symbol cannot contain '\\0'" if symbol && c =~ /\0/
      end # unless handled

      c ||= matched
      string_buffer << c
    end # until

    c ||= matched
    c = RubyLexer::EOF if end_of_stream?

    return c
  end

  def unescape s
    r = ESCAPES[s]

    self.extra_lineno += 1 if s == "\n"     # eg backslash newline strings
    self.extra_lineno -= 1 if r && s == "n" # literal \n, not newline

    return r if r

    x = case s
        when /^[0-7]{1,3}/ then
          ($&.to_i(8) & 0xFF).chr
        when /^x([0-9a-fA-F]{1,2})/ then
          $1.to_i(16).chr
        when /^M-(.)/ then
          ($1[0].ord | 0x80).chr
        when /^(C-|c)(.)/ then
          ($2[0].ord & 0x9f).chr
        when /^[89a-f]/i then # bad octal or hex... ignore? that's what MRI does :(
          s
        when /^[McCx0-9]/ then
          rb_compile_error("Invalid escape character syntax")
        when /u(\h{4})/ then
          [$1.delete("{}").to_i(16)].pack("U")
        when /u(\h{1,3})/ then
          rb_compile_error("Invalid escape character syntax")
        when /u\{(\h+(?:\s+\h+)*)\}/ then
          $1.split.map { |s| s.to_i(16) }.pack("U*")
        else
          s
        end
    x
  end

  def warning s
    # do nothing for now
  end

  def was_label?
    @was_label = ruby22_label?
    true
  end

  class State
    attr_accessor :n
    attr_accessor :names

    # TODO: take a shared hash of strings for inspect/to_s
    def initialize o, names
      raise ArgumentError, "bad state: %p" % [o] unless Integer === o # TODO: remove

      self.n = o
      self.names = names
    end

    def == o
      self.equal?(o) || (o.class == self.class && o.n == self.n)
    end

    def =~ v
      (self.n & v.n) != 0
    end

    def | v
      raise ArgumentError, "Incompatible State: %p vs %p" % [self, v] unless
        self.names == v.names
      self.class.new(self.n | v.n, self.names)
    end

    def inspect
      return "Value(0)" if n.zero? # HACK?

      names.map { |v, k| k if self =~ v }.
        compact.
        join("|").
        gsub(/(?:EXPR_|STR_(?:FUNC_)?)/, "")
    end

    alias to_s inspect

    module Values
      expr_names = {}

      EXPR_NONE    = State.new    0x0, expr_names
      EXPR_BEG     = State.new    0x1, expr_names
      EXPR_END     = State.new    0x2, expr_names
      EXPR_ENDARG  = State.new    0x4, expr_names
      EXPR_ENDFN   = State.new    0x8, expr_names
      EXPR_ARG     = State.new   0x10, expr_names
      EXPR_CMDARG  = State.new   0x20, expr_names
      EXPR_MID     = State.new   0x40, expr_names
      EXPR_FNAME   = State.new   0x80, expr_names
      EXPR_DOT     = State.new  0x100, expr_names
      EXPR_CLASS   = State.new  0x200, expr_names
      EXPR_LABEL   = State.new  0x400, expr_names
      EXPR_LABELED = State.new  0x800, expr_names
      EXPR_FITEM   = State.new 0x1000, expr_names

      EXPR_BEG_ANY = EXPR_BEG | EXPR_MID    | EXPR_CLASS
      EXPR_ARG_ANY = EXPR_ARG | EXPR_CMDARG
      EXPR_END_ANY = EXPR_END | EXPR_ENDARG | EXPR_ENDFN

      # extra fake lex_state names to make things a bit cleaner

      EXPR_LAB = EXPR_ARG|EXPR_LABELED
      EXPR_LIT = EXPR_END|EXPR_ENDARG
      EXPR_PAR = EXPR_BEG|EXPR_LABEL
      EXPR_PAD = EXPR_BEG|EXPR_LABELED

      EXPR_NUM = EXPR_LIT

      expr_names.merge!(EXPR_NONE    => "EXPR_NONE",
                        EXPR_BEG     => "EXPR_BEG",
                        EXPR_END     => "EXPR_END",
                        EXPR_ENDARG  => "EXPR_ENDARG",
                        EXPR_ENDFN   => "EXPR_ENDFN",
                        EXPR_ARG     => "EXPR_ARG",
                        EXPR_CMDARG  => "EXPR_CMDARG",
                        EXPR_MID     => "EXPR_MID",
                        EXPR_FNAME   => "EXPR_FNAME",
                        EXPR_DOT     => "EXPR_DOT",
                        EXPR_CLASS   => "EXPR_CLASS",
                        EXPR_LABEL   => "EXPR_LABEL",
                        EXPR_LABELED => "EXPR_LABELED",
                        EXPR_FITEM   => "EXPR_FITEM")

      # ruby constants for strings

      str_func_names = {}

      STR_FUNC_BORING = State.new 0x00,    str_func_names
      STR_FUNC_ESCAPE = State.new 0x01,    str_func_names
      STR_FUNC_EXPAND = State.new 0x02,    str_func_names
      STR_FUNC_REGEXP = State.new 0x04,    str_func_names
      STR_FUNC_QWORDS = State.new 0x08,    str_func_names
      STR_FUNC_SYMBOL = State.new 0x10,    str_func_names
      STR_FUNC_INDENT = State.new 0x20,    str_func_names # <<-HEREDOC
      STR_FUNC_LABEL  = State.new 0x40,    str_func_names
      STR_FUNC_LIST   = State.new 0x4000,  str_func_names
      STR_FUNC_TERM   = State.new 0x8000,  str_func_names
      STR_FUNC_ICNTNT = State.new 0x10000, str_func_names # <<~HEREDOC -- TODO: remove?

      # TODO: check parser25.y on how they do STR_FUNC_INDENT

      STR_SQUOTE = STR_FUNC_BORING
      STR_DQUOTE = STR_FUNC_EXPAND
      STR_XQUOTE = STR_FUNC_EXPAND
      STR_REGEXP = STR_FUNC_REGEXP | STR_FUNC_ESCAPE | STR_FUNC_EXPAND
      STR_SWORD  = STR_FUNC_QWORDS | STR_FUNC_LIST
      STR_DWORD  = STR_FUNC_QWORDS | STR_FUNC_EXPAND | STR_FUNC_LIST
      STR_SSYM   = STR_FUNC_SYMBOL
      STR_DSYM   = STR_FUNC_SYMBOL | STR_FUNC_EXPAND

      str_func_names.merge!(STR_FUNC_ESCAPE => "STR_FUNC_ESCAPE",
                            STR_FUNC_EXPAND => "STR_FUNC_EXPAND",
                            STR_FUNC_REGEXP => "STR_FUNC_REGEXP",
                            STR_FUNC_QWORDS => "STR_FUNC_QWORDS",
                            STR_FUNC_SYMBOL => "STR_FUNC_SYMBOL",
                            STR_FUNC_INDENT => "STR_FUNC_INDENT",
                            STR_FUNC_LABEL  => "STR_FUNC_LABEL",
                            STR_FUNC_LIST   => "STR_FUNC_LIST",
                            STR_FUNC_TERM   => "STR_FUNC_TERM",
                            STR_FUNC_ICNTNT => "STR_FUNC_ICNTNT",
                            STR_SQUOTE      => "STR_SQUOTE")
    end

    include Values
  end

  include State::Values
end

require "ruby_lexer.rex"

if ENV["RP_LINENO_DEBUG"] then
  class RubyLexer
    def d o
      $stderr.puts o.inspect
    end

    alias old_lineno= lineno=

    def lineno= n
      self.old_lineno= n
      where = caller.first.split(/:/).first(2).join(":")
      d :lineno => [n, where, ss && ss.rest[0, 40]]
    end
  end
end
