###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

unless defined?(TESTDIR)
  TESTDIR = File.dirname(__FILE__)
  #libdir  = TESTDIR == '.' ? '../lib' : File.dirname(TESTDIR) + "/lib"
  libdir  = TESTDIR == '.' ? File.expand_path('../lib') : File.dirname(TESTDIR) + "/lib"
  $LOAD_PATH << libdir << TESTDIR
end


class StringWriter < String
  alias write <<
end


class Hash
  def inspect
    buf = [ '{' ]
    self.keys.sort_by {|k| k.to_s }.each_with_index do |key, i|
      buf << ', ' if i > 0
      buf << key.inspect << '=>' << self[key].inspect
    end
    buf << '}'
    return buf.join
  end
end


require 'test/unit'
require 'yaml'
require 'pp'
require 'kwalify'
require 'kwalify/util'
require 'kwalify/util/assert-text-equal'
require 'kwalify/util/testcase-helper'


if $0 == __FILE__

  require 'test-parser-yaml.rb'
  require 'test-yaml-parser.rb'
  require 'test-rule.rb'
  require 'test-validator.rb'
  require 'test-metavalidator.rb'
  require 'test-databinding.rb'
  require 'test-main.rb'
  require 'test-action.rb'
  require 'test-users-guide.rb'
  require 'test-util.rb'

  #suite = Test::Unit::TestSuite.new()
  #suite << ValidatorTest.suite()
  #suite << MetaValidatorTest.suite()
  #suite << ParserTest.suite()
  #Test::Unit::UI::Console::TestRunner.run(suite)

end
