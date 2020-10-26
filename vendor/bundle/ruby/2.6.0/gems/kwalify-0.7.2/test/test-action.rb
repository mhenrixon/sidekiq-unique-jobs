###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'

require 'kwalify/main'


module Kwalify
  class Main
    public :_parse_argv
  end
end


class File
  def self.move(filename, dirname)
    File.rename(filename, "#{dirname}/#{filename}")
  end
end


class ActionTest < Test::Unit::TestCase

  ## define test methods
  filename = __FILE__.sub(/\.rb$/, ".yaml")
  load_yaml_testdata(filename, :lang=>'ruby')


  ## temporary directory
  @@tmpdir = "tmp.dir"
  Dir.mkdir(@@tmpdir) unless test(?d, @@tmpdir)


  def _test
    if @exception
      classname = @exception =~ /Kwalify::(.*)/ ? $1 : @exception
      @exception_class = Kwalify.const_get(classname)
    end
    return if $target && $target != @name
    raise "*** #{@name}: args is required."    unless @args
    raise "*** #{@name}: expected is require." unless @expected
    #
    File.open("#{@name}.schema", 'w')   { |f| f.write(@schema)   } if @schema
    File.open("#{@name}.document", 'w') { |f| f.write(@document) } if @document
    #
    begin
      main = Kwalify::Main.new("kwalify")
      $stdout = StringWriter.new
      main.execute(@args)
      actual = $stdout;  $stdout = STDOUT
      if @output_files
        if @output_message
          assert_text_equal(@output_message, actual)
        else
          assert(actual.nil? || actual=='')
        end
        @output_files.each do |filename|
          actual = File.read(filename)
          assert_text_equal(@expected[filename], actual)
        end
      else
        assert_text_equal(@expected, actual)
      end
    ensure
      File.move("#{@name}.schema",   @@tmpdir) if @schema
      File.move("#{@name}.document", @@tmpdir) if @document
      @output_files.each do |filename|
        File.move(filename, @@tmpdir) if test(?f, filename)
      end if @output_files
    end
  end


end
