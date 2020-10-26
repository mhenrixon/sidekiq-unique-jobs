# :stopdoc:
# WHY do I have to do this?!?
class Regexp
  ONCE = 0 unless defined? ONCE # FIX: remove this - it makes no sense

  unless defined? ENC_NONE then
    ENC_NONE = /x/n.options
    ENC_EUC  = /x/e.options
    ENC_SJIS = /x/s.options
    ENC_UTF8 = /x/u.options
  end
end
# :startdoc:

############################################################
# HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK

unless "".respond_to?(:grep) then
  class String
    def grep re
      lines.grep re
    end
  end
end

class String
  ##
  # This is a hack used by the lexer to sneak in line numbers at the
  # identifier level. This should be MUCH smaller than making
  # process_token return [value, lineno] and modifying EVERYTHING that
  # reduces tIDENTIFIER.

  attr_accessor :lineno

  def clean_caller
    self.sub(File.dirname(__FILE__), "./lib").sub(/:in.*/, "")
  end if $DEBUG
end

require "sexp"

class Sexp
  attr_writer :paren

  def paren
    @paren ||= false
  end

  def value
    raise "multi item sexp" if size > 2
    last
  end

  def to_sym
    raise "no: #{self.inspect}.to_sym is a bug"
    self.value.to_sym
  end

  alias :add :<<

  def add_all x
    self.concat x.sexp_body
  end

  def block_pass?
    any? { |s| Sexp === s && s.sexp_type == :block_pass }
  end

  alias :node_type :sexp_type
  alias :values :sexp_body # TODO: retire
end

# END HACK
############################################################
