###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

module Kwalify

  module Util

    module_function

    ##
    ## expand tab character to spaces
    ##
    ## ex.
    ##   untabified_str = YamlHelper.untabify(tabbed_str)
    ##
    def untabify(str, width=8)
      return str if str.nil?
      list = str.split(/\t/, -1)   # if 2nd arg is negative then split() doesn't remove tailing empty strings
      last = list.pop
      sb = ''
      list.each do |s|
        column = (n = s.rindex(?\n)) ? s.length - n - 1 : s.length
        n = width - (column % width)
        sb << s << (' ' * n)
      end
      sb << last if last
      return sb
    end


    ## traverse schema
    ##
    ## ex.
    ##   schema = YAML.load_file('myschema.yaml')
    ##   Kwalify::Util.traverse_schema(schema) do |rulehash|
    ##     ## add module prefix to class name
    ##     if rulehash['class']
    ##       rulehash['class'] = 'MyModule::' + rulehash['class']
    ##     end
    ##   end
    def traverse_schema(schema, &block)  #:yield: rulehash
      hash = schema
      _done = {}
      _traverse_schema(hash, _done, &block)
    end

    def _traverse_schema(hash, _done={}, &block)
      return if _done.key?(hash.__id__)
      _done[hash.__id__] = hash
      yield hash
      if hash['mapping']
        hash['mapping'].each {|k, v| _traverse_schema(v, _done, &block) }
      elsif hash['sequence']
        _traverse_schema(hash['sequence'][0], _done, &block)
      end
    end
    private :_traverse_schema


    ## traverse rule
    ##
    ## ex.
    ##   schema = YAML.load_file('myschema.yaml')
    ##   validator = Kwalify::Validator.new(schema)
    ##   Kwalify::Util.traverse_rule(validator) do |rule|
    ##     p rule if rule.classname
    ##   end
    def traverse_rule(validator, &block)  #:yield: rule
      rule = validator.is_a?(Rule) ? validator : validator.rule
      _done = {}
      _traverse_rule(rule, _done, &block)
    end

    def _traverse_rule(rule, _done={}, &block)
       return if _done.key?(rule.__id__)
       _done[rule.__id__] = rule
       yield rule
       rule.sequence.each do |seq_rule|
          _traverse_rule(seq_rule, _done, &block)
       end if rule.sequence
       rule.mapping.each do |name, map_rule|
          _traverse_rule(map_rule, _done, &block)
       end if rule.mapping
    end
    private :_traverse_rule


    ##
    ## get class object. if not found, NameError raised.
    ##
    def get_class(classname)
      klass = Object
      classname.split('::').each do |name|
        klass = klass.const_get(name)
      end
      return klass
    end


    ##
    ## create a hash table from list of hash with primary key.
    ##
    ## ex.
    ##   hashlist = [
    ##     { "name"=>"Foo", "gender"=>"M", "age"=>20, },
    ##     { "name"=>"Bar", "gender"=>"F", "age"=>25, },
    ##     { "name"=>"Baz", "gender"=>"M", "age"=>30, },
    ##   ]
    ##   hashtable = YamlHelper.create_hashtable(hashlist, "name")
    ##   p hashtable
    ##       # => { "Foo" => { "name"=>"Foo", "gender"=>"M", "age"=>20, },
    ##       #      "Bar" => { "name"=>"Bar", "gender"=>"F", "age"=>25, },
    ##       #      "Baz" => { "name"=>"Baz", "gender"=>"M", "age"=>30, }, }
    ##
    def create_hashtable(hashlist, primarykey, flag_duplicate_check=true)
      hashtable = {}
      hashlist.each do |hash|
        key = hash[primarykey]
        unless key
          riase "primary key '#{key}' not found."
        end
        if flag_duplicate_check && hashtable.key?(key)
          raise "primary key '#{key}' duplicated (value '#{hashtable[key]}')"
        end
        hashtable[key] = hash
      end if hashlist
      return hashtable
    end


    ##
    ## get nested value directly.
    ##
    ## ex.
    ##   val = YamlHelper.get_value(obj, ['aaa', 0, 'xxx'])
    ##
    ## This is equal to the following:
    ##   begin
    ##     val = obj['aaa'][0]['xxx']
    ##   rescue NameError
    ##     val = nil
    ##   end
    ##
    def get_value(obj, path)
      val = obj
      path.each do |key|
        return nil unless val.is_a?(Hash) || val.is_a?(Array)
        val = val[key]
      end if path
      return val
    end

  end

end
