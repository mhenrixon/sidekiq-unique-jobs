###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'


class RuleTest < Test::Unit::TestCase

  ## define test methods
  filename = __FILE__.sub(/\.rb$/, '.yaml')
  load_yaml_testdata(filename, :lang=>'ruby')


  ## execute test
  def _test()
    assert_nothing_raised do
      return if $target && $target != @name
      schema = @schema
      rule = Kwalify::Rule.new(schema)
    end
  end

end
