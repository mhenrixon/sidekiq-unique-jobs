###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'


class ValidatorTest < Test::Unit::TestCase


  ## define test methods
  filename = __FILE__.sub(/\.rb$/, '.yaml')
  load_yaml_testdata(filename, :lang=>'ruby')


  ## execute test
  def _test()
    return if $target && $target != @name
    ## Syck parser
    schema = YAML.load(@schema)
    validator = Kwalify::Validator.new(schema)
    error2 = @error.gsub(/\(line \d+\)/, '')
    _test_by_syck_parser(validator, @valid,   ''    )
    _test_by_syck_parser(validator, @invalid, error2)
    ## Kwalify::YamlParser
    schema = Kwalify::YamlParser.new(@schema).parse()
    validator = Kwalify::Validator.new(schema)
    _test_by_kwalify_yamlparser(validator, @valid,   ''    )
    _test_by_kwalify_yamlparser(validator, @invalid, @error)
    ## Kwalify::Yaml::Parser
    schema = Kwalify::Yaml::Parser.new().parse(@schema)
    validator = Kwalify::Validator.new(schema)
    _test_by_kwalify_yaml_parser(validator, @valid,   ''    )
    _test_by_kwalify_yaml_parser(validator, @invalid, @error2 || @error)
  end


  def _test_by_kwalify_yamlparser(validator, input, expected)
    parser = Kwalify::YamlParser.new(input)
    document = parser.parse()
    error_list  = validator.validate(document)
    parser.set_errors_linenum(error_list)
    error_list.sort!
    actual = ''
    error_list.each do |error|
      e = error
      args = [e.error_symbol.inspect, e.linenum, e.path, e.message]
      actual << "%-20s: (line %d)[%s] %s\n" % args
    end
    if $print
      print actual
    else
      assert_text_equal(expected, actual)
    end
  end


  def _test_by_kwalify_yaml_parser(validator, input, expected)
    parser = Kwalify::Yaml::Parser.new(validator)
    document = parser.parse(input)
    error_list  = parser.errors()
    error_list.sort!
    actual = ''
    error_list.each do |error|
      e = error
      args = [e.error_symbol.inspect, e.linenum, e.column, e.path, e.message]
      #actual << "%-20s: (line %d)[%s] %s\n" % args
      actual << "%-20s: %d:%d:[%s] %s\n" % args
    end
    if $print
      print actual
    else
      assert_text_equal(expected, actual)
    end
  end


  def _test_by_syck_parser(validator, input, expected)
    document = YAML.load(input)
    error_list  = validator.validate(document)
    expected = expected.to_a.sort.join()
    actual = error_list.collect { |e|
      "%-20s: [%s] %s\n" % [e.error_symbol.inspect, e.path, e.message]
    }.sort.join()
    if $print
      print actual
    else
      assert_text_equal(expected, actual)
    end
  end


end
