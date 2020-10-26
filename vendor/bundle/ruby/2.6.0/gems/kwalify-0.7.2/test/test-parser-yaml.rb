###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'



class YamlParserTest < Test::Unit::TestCase

  filename = __FILE__.sub(/\.rb$/, '.yaml')
  load_yaml_testdata(filename, :lang=>'ruby')

  def _test()
    if @exception
      @error_class = @exception.split(/::/).inject(Kernel) { |c,s| c = c.const_get(s) }
    end
    parser = Kwalify::Yaml::Parser.new()
    @testopts ||= {}
    parser.preceding_alias = true if @testopts['preceding_alias']
    if @error_class
      ex = assert_raise(@error_class) do
        doc = parser.parse(@input)
      end
    else
      doc = parser.parse(@input)
      if @testopts['pp'] || @testopts['recursive']
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
        #t = parser.instance_variable_get("@location_table")
        #require 'pp'
        if @locations
          @locations.each do |path, expected_linenum, expected_column|
            linenum, column = parser.location(path)
            assert_equal(expected_linenum, linenum)
            assert_equal(expected_column, column)
          end
        end
      end
    end
  end

end
