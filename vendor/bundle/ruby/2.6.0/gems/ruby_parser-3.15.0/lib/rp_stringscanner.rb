require "strscan"

class RPStringScanner < StringScanner
#   if ENV['TALLY'] then
#     alias :old_getch :getch
#     def getch
#       warn({:getch => caller[0]}.inspect)
#       old_getch
#     end
#   end

  if "".respond_to? :encoding then
    if "".respond_to? :byteslice then
      def string_to_pos
        string.byteslice(0, pos)
      end
    else
      def string_to_pos
        string.bytes.first(pos).pack("c*").force_encoding(string.encoding)
      end
    end

    def charpos
      string_to_pos.length
    end
  else
    alias :charpos :pos

    def string_to_pos
      string[0..pos]
    end
  end

  def unread_many str # TODO: remove this entirely - we should not need it
    warn({:unread_many => caller[0]}.inspect) if ENV['TALLY']
    begin
      string[charpos, 0] = str
    rescue IndexError
      # HACK -- this is a bandaid on a dirty rag on an open festering wound
    end
  end

  if ENV['DEBUG'] then
    alias :old_getch :getch
    def getch
      c = self.old_getch
      p :getch => [c, caller.first]
      c
    end

    alias :old_scan :scan
    def scan re
      s = old_scan re
      where = caller[1].split(/:/).first(2).join(":")
      d :scan => [s, where] if s
      s
    end
  end

  def d o
    $stderr.puts o.inspect
  end
end

