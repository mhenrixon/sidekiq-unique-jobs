###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require File.dirname(__FILE__) + '/test.rb'

require 'kwalify/util'


class UtilTest < Test::Unit::TestCase

  def spec(detail)
    yield
  end

  def test_untabify
    spec "converts tab characters to spaces" do
      input    = "123\t999"
      expected = "123     999"
      assert_text_equal expected, Kwalify::Util.untabify(input)
    end
    spec "able to specify column width" do
      input    = "12\t999"
      expected = "12  999"
      assert_text_equal expected, Kwalify::Util.untabify(input, 4)
    end
    spec "able to handle multiline string" do
      input    = "123\n\t456\n789\t0"
      expected = "123\n        456\n789     0"
      assert_text_equal expected, Kwalify::Util.untabify(input)
    end
    spec "returns nil if argument is nil" do
      assert_nil Kwalify::Util.untabify(nil)
    end
    spec "don't remove tailing spaces" do   # bugfix
      input    = "abc\t\t"
      expected = "abc             "
      assert_text_equal expected, Kwalify::Util.untabify(input)
    end
  end

  SCHEMA1 = <<END
type: seq
sequence:
  - type: map
    class: Member
    mapping:
     "name": { type: str, required: true }
     "age":  { type: int, required: false }
END

  def test_traverse
    spec "traverse schema structure" do
      schema = YAML.load(SCHEMA1)
      assert_equal "Member", schema["sequence"][0]["class"]
      Kwalify::Util.traverse_schema(schema) do |rulehash|
        ## add module prefix to class name
        if rulehash['class']
          rulehash['class'] = 'MyModule::' + rulehash['class']
        end
      end
      assert_equal "MyModule::Member", schema["sequence"][0]["class"]
    end
  end

  def test_traverse_rule
    spec "traverse rule" do
      schema = YAML.load(SCHEMA1)
      validator = Kwalify::Validator.new(schema)
      rules = []
      Kwalify::Util.traverse_rule(validator) do |rule|
        rules << rule
      end
      assert_equal 4, rules.length
      assert_text_equal <<'END', rules[0].send(:_inspect)
type:    seq
klass:    Array
  - 
    type:    map
    klass:    Hash
      "name":
        type:    str
        klass:    String
        required:  true
      "age":
        type:    int
        klass:    Integer
        required:  false
END
      assert_text_equal <<'END', rules[1].send(:_inspect)
type:    map
klass:    Hash
  "name":
    type:    str
    klass:    String
    required:  true
  "age":
    type:    int
    klass:    Integer
    required:  false
END
      assert_text_equal <<'END', rules[2].send(:_inspect)
type:    str
klass:    String
required:  true
END
      assert_text_equal <<'END', rules[3].send(:_inspect)
type:    int
klass:    Integer
required:  false
END
    end
  end

  def test_get_value
    schema = YAML.load(SCHEMA1)
    path = ['sequence', 0, 'mapping', 'name', 'type']
    assert_equal 'str', Kwalify::Util.get_value(schema, path)
    path = ['sequence', 1, 'mapping', 'name', 'type']
    assert_equal nil,   Kwalify::Util.get_value(schema, path)
  end

end
