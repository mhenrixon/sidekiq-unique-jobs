###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'


class ParserTest < Test::Unit::TestCase

  filename = __FILE__.sub(/\.rb$/, '.yaml')
  load_yaml_testdata(filename, :lang=>'ruby')

  def _test()
    if @exception
      @error_class = @exception.split(/::/).inject(Kernel) { |k,s| k = k.const_get(s) }
      #@error_class = Kwalify::YamlSyntaxError if @error_class == Kwalify::SyntaxError
    end
    parser = Kwalify::YamlParser.new(@input)
    if @error_class
      assert_raise(@error_class) do
        doc = parser.parse()
      end
    else
      doc = parser.parse()
      #if @recursive || @pp
      if @testopts && (@testopts['recursive'] || @testopts['pp'])
        s = StringWriter.new
        PP.pp(doc, s)
        actual = s
      else
        actual = doc.inspect + "\n"
      end
      if $log
        File.open("#{@name}.expected", 'w') { |f| f.write(@expected) }
        File.open("#{@name}.actual", 'w') { |f| f.write(actual) }
      end
      if $print
        print actual
      else
        assert_text_equal(@expected, actual)
      end
    end
  end

end
