###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'yaml'
require 'test/unit/testcase'


class Test::Unit::TestCase   # :nodoc:


  def self._untabify(str, width=8)         # :nodoc:
    sb = []
    str.scan(/(.*?)\t/m) do |s, |
      len = (n = s.rindex(?\n)) ? s.length - n - 1 : s.length
      sb << s << (" " * (width - len % width))
    end
    str = (sb << $').join if $'
    return str
  end


  def self.load_yaml_documents(filename, options={})   # :nodoc:
    str = File.read(filename)
    if filename =~ /\.rb$/
      str =~ /^__END__$/   or raise "*** error: __END__ is not found in '#{filename}'."
      str = $'
    end
    str = _untabify(str) unless options[:tabify] == false
    #
    identkey = options[:identkey] || 'name'
    list = []
    table = {}
    YAML.load_documents(str) do |ydoc|
      if ydoc.is_a?(Hash)
        list << ydoc
      elsif ydoc.is_a?(Array)
        list += ydoc
      else
        raise "*** invalid ydoc: #{ydoc.inspect}"
      end
    end
    #
    list.each do |ydoc|
      ident = ydoc[identkey]
      ident         or  raise "*** #{identkey} is not found."
      table[ident]  and raise "*** #{identkey} '#{ident}' is duplicated."
      table[ident] = ydoc
      yield(ydoc) if block_given?
    end
    #
    return list
  end


  def self.load_yaml_testdata(filename, options={})   # :nodoc:
    identkey   = options[:identkey]   || 'name'
    testmethod = options[:testmethod] || '_test'
    lang       = options[:lang]
    load_yaml_documents(filename, options) do |ydoc|
      ident = ydoc[identkey]
      s  =   "def test_#{ident}\n"
      ydoc.each do |key, val|
        if key[-1] == ?*
          key = key[0, key.length-1]
          val = val[lang]
        end
        s << "  @#{key} = #{val.inspect}\n"
      end
      s  <<  "  #{testmethod}\n"
      s  <<  "end\n"
      #$stderr.puts "*** #{method_name()}(): eval_str=<<'END'\n#{s}END" if $DEBUG
      module_eval s   # not eval!
    end
  end


  def self.method_name   # :nodoc:
    return (caller[0] =~ /in `(.*?)'/) && $1
  end


  def self.load_yaml_testdata_with_each_lang(filename, options={})   # :nodoc:
    identkey   = options[:identkey]   || 'name'
    testmethod = options[:testmethod] || '_test'
    langs = defined?($lang) && $lang ? [ $lang ] : options[:langs]
    langs or raise "*** #{method_name()}(): option ':langs' is required."
    #
    load_yaml_documents(filename, options) do |ydoc|
      ident = ydoc[identkey]
      langs.each do |lang|
        s  =   "def test_#{ident}_#{lang}\n"
        s  <<  "  @lang = #{lang.inspect}\n"
        ydoc.each do |key, val|
          if key[-1] == ?*
            key = key[0, key.length-1]
            val = val[lang]
          end
          s << "  @#{key} = #{val.inspect}\n"
        end
        s  <<  "  #{testmethod}\n"
        s  <<  "end\n"
        #$stderr.puts "*** #{method_name()}(): eval_str=<<'END'\n#{s}END" if $DEBUG
        module_eval s   # not eval!
      end
    end
  end


end
