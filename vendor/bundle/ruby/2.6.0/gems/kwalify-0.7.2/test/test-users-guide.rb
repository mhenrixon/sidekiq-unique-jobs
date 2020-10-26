require File.expand_path(File.dirname(__FILE__) + '/../test/test.rb')

class UsersGuideTest < Test::Unit::TestCase

  DATA_DIR = 'data/users-guide'
  CURR_DIR = Dir.pwd
  for item in Dir.glob("#{DATA_DIR}/*.result").sort()
    filename = File.basename(item)
    name = (filename =~ /(.*)\.\w+$/) && $1.gsub(/[^\w]/, '_')
    s = <<-END
      def test_#{name}
        @name = #{name.inspect}
        @filename = #{filename.inspect}
        _test()
      end
    END
    eval s
  end

### BEGIN
  def test_address_book_ruby
    @command = 'kwalify -a genclass-ruby -tf address_book.schema.yaml'
    @result = File.read('address_book.rb')
    _test()
  end
  def test_example_address_book_ruby
    @command = 'ruby example_address_book.rb'
    @result = File.read('example_address_book_ruby.result')
    @testopts = { 'delete_object_id' => true }
    _test()
  end
### END

  def setup
    Dir.chdir DATA_DIR
  end

  def teardown
    Dir.chdir CURR_DIR
  end

  def _test
    #@name ||= (caller()[0] =~ /in `test_(.*?)'/) && $1
    @name = (self.name =~ /\Atest_(.*)\(.*\)\z/) && $1
    return if @name =~ /\_java$/
    @filename ||= @name + '.result'

    result = @result || File.read(@filename)
    tuples = result.split(/^(?=\$ )/).collect do |s|
      if s.sub!(/\A\$ (.*)\n/, '')
        command = $1
        while command =~ /\\\z/
          command.chop!
          s.sub!(/\A(.*)\n/, '')
          command << $1
        end
        [@command || command, @expected || s]
      else
        [@command, @expected || s]
      end
    end

    tuples.each do |command, expected|
      actual = @actual || `#{command}`
      #if @testopts && @testops['delete_object_id']
        rexp = /(\#<\w+(::\w+)*:)0x[0-9a-f]+/
        actual.gsub!(rexp, '\1')
        expected.gsub!(rexp, '\1')
      #end
      assert_text_equal(expected, actual)
    end

  end

end
