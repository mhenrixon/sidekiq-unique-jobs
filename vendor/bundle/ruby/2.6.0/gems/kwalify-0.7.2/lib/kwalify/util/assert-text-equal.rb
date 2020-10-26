###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'test/unit/testcase'
require 'tempfile'


class Test::Unit::TestCase  # :nodoc:

  def assert_text_equal(expected, actual, message=nil, options={}) # :nodoc:
    expected = expected.to_s
    actual   = actual.to_s
    diffopt  = options[:diffopt] || '-u'
    flag_cut = options.key?(:cut) ? options[:key] : true

    if expected == actual
      assert(true)
      return
    end
    if expected[-1] != ?\n || actual[-1] != ?\n
      expected += "\n"
      actual   += "\n"
    end
    begin
      expfile = Tempfile.new(".expected.")
      expfile.write(expected); expfile.flush()
      actfile = Tempfile.new(".actual.")
      actfile.write(actual);   actfile.flush()
      diff = `diff #{diffopt} #{expfile.path} #{actfile.path}`
    ensure
      expfile.close(true) if expfile
      actfile.close(true) if actfile
    end
    # cut 1st & 2nd lines
    message = (flag_cut ? diff.gsub(/\A.*\n.*\n/, '') : diff) unless message
    #raise Test::Unit::AssertionFailedError.new(message)
    assert_block(message) { false }  # or assert(false, message)
  end

  alias assert_equal_with_diff assert_text_equal    # for compatibility
  alias assert_text_equals     assert_text_equal    # for typo

end
