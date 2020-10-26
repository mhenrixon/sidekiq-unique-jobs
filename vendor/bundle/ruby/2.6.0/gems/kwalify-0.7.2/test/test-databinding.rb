###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'


class DataBindingTest < Test::Unit::TestCase


  ## define test methods
  filename = __FILE__.sub(/\.rb$/, '.yaml')
  input = Kwalify::Util.untabify(File.read(filename))
  TESTDATA1 = {}
  YAML.load_documents(input) do |ydoc|
    hash_list = ydoc
    hash_list.each do |hash|
      for key in hash.keys()
        hash[key[0..-2]] = hash.delete(key)['ruby'] if key[-1] == ?*
      end
      name = hash['name'] or raise "name is not found."
      TESTDATA1.key?(name) and raise "name '#{name}' is dupilcated."
      TESTDATA1[name] = hash
      #
      s = ''
      s <<   "def test_#{name}\n"
      s <<   "  @name = '#{name}'\n"
      for key, val in hash
        s << "  @#{key} = TESTDATA1['#{name}']['#{key}']\n"
      end
      s <<   "  _test\n"
      s <<   "end\n"
      eval s
    end
  end
  load_yaml_testdata(filename, :lang=>'ruby')


  def _test
    ## schema
    if @schema.is_a?(String)
      @schema = Kwalify::Yaml::Parser.new.parse(@schema, :untabify=>true)
      #@schema = YAML.load(Kwalify::Util.untabify(@schema))
    end
    ## data binding
    #Object.class_eval {@classdef} if @classdef
    if @classdef
      Object.class_eval @classdef
    end
    validator = Kwalify::Validator.new(@schema)
    parser = Kwalify::Yaml::Parser.new(validator, :data_binding=>true)
    @testopts ||= {}
    parser.preceding_alias = true if @testopts['preceding_alias']
    ydoc = parser.parse(@data)
    assert_equal(parser.errors, [])
    ## pp
    result = ''
    def result.write(arg); self << arg.to_s; end
    PP.pp(ydoc, result)
    ## convert object-id to portable number
    table = {}
    counter = 0
    result.gsub!(/:0x\w+/) {|m| ":0x%03d" % (table[m] ||= (counter+=1)) }
    ## assert
    #puts result
    assert_text_equal(@expected, result)
    ## path, linenum, column
    if @locations
      #t = parser.instance_variable_get("@location_table")
      #require 'pp'
      #pp t
      @locations.each do |path, expected_linenum, expected_column|
        linenum, column = parser.location(path)
        assert_equal(expected_linenum, linenum)
        assert_equal(expected_column, column)
      end
    end
  end


end
