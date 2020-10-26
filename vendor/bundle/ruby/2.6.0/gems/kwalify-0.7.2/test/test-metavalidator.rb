###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'


class MetaValidatorTest < Test::Unit::TestCase

  ## define test methods
  filename = __FILE__.sub(/\.rb$/, '.yaml')
  load_yaml_documents(filename) do |ydoc|
    name = ydoc['name']
    ydoc.each do |key, val|
      ydoc[$1] = val['ruby'] if key =~ /(.*)\*$/
    end
    s = <<-END
         def test_meta_#{name}
            @name    = #{ydoc['name'].inspect}
            @desc    = #{ydoc['desc'].inspect}
            @schema  = #{ydoc['schema'].inspect}
            @meta_msg = #{ydoc['meta-msg'].inspect}
            # @rule_msg = #{ydoc['rule-msg'].inspect}
            @test_type = :meta
            _test
         end
      END
    module_eval s if ydoc['meta-msg']
    s = <<-END
         def test_rule_#{name}
            @name    = #{ydoc['name'].inspect}
            @desc    = #{ydoc['desc'].inspect}
            @schema  = #{ydoc['schema'].inspect}
            # @meta_msg = #{ydoc['meta-msg'].inspect}
            @rule_msg = #{ydoc['rule-msg'].inspect}
            @test_type = :rule
            _test
         end
      END
    module_eval s if ydoc['rule-msg']
  end


  ## execute test
  def _test()
    return if $target && $target != @name
    #schema = YAML.load(@schema)
    parser = Kwalify::YamlParser.new(@schema)
    schema = parser.parse()
    case @test_type
    when :meta
      meta_validator = Kwalify::MetaValidator.instance()
      errors = meta_validator.validate(schema)
      parser.set_errors_linenum(errors)
      errors.sort!
      expected = @meta_msg
    when :rule
      errors = []
      begin
        rule = Kwalify::Validator.new(schema)
      rescue Kwalify::KwalifyError => error
        errors << error
      end
      expected = @rule_msg
    end
    actual = ''
    errors.each do |error|
      raise error if error.is_a?(Kwalify::AssertionError)
      actual << "%-20s: [%s] %s\n" % [error.error_symbol.inspect, error.path, error.message]
    end
    if $print
      print actual
    else
      assert_text_equal(expected, actual)
    end
  end

end
