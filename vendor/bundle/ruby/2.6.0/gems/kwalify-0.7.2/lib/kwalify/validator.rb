###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'kwalify/messages'
require 'kwalify/errors'
require 'kwalify/types'
require 'kwalify/rule'

module Kwalify

  ##
  ## validate YAML document
  ##
  ## ex1. validate yaml document
  ##   schema = YAML.load_file('schema.yaml')
  ##   validator = Kwalify::Validator.new(schema)
  ##   document = YAML.load_file('document.yaml')
  ##   erros = validator.validate(document)
  ##   if errors && !errors.empty?
  ##     errors.each do |err|
  ##       puts "- [#{err.path}] #{err.message}"
  ##     end
  ##   end
  ##
  ## ex2. validate with parsing
  ##   schema = YAML.load_file('schema.yaml')
  ##   validator = Kwalify::Validator.new(schema)
  ##   parser = Kwalify::Yaml::Parser.new(validator)
  ##   document = parser.parse(File.read('document.yaml'))
  ##   errors = parser.errors
  ##   if errors && errors.empty?
  ##     errors.each do |e|
  ##       puts "#{e.linenum}:#{e.column} [#{e.path}] #{e.message}"
  ##     end
  ##   end
  ##
  class Validator
    include Kwalify::ErrorHelper


    def initialize(hash_or_rule, &block)
      obj = hash_or_rule
      @rule = (obj.nil? || obj.is_a?(Rule)) ? obj : Rule.new(obj)
      @block = block
    end
    attr_reader :rule


    def _inspect
      @rule._inspect
    end


    def validate(value)
      path = '';  errors = [];  done = {};  uniq_table = nil
      _validate(value, @rule, path, errors, done, uniq_table)
      return errors
    end


    protected


    def validate_hook(value, rule, path, errors)
      ## may be overrided by subclass
    end


    public


    def _validate(value, rule, path, errors, done, uniq_table, recursive=true)
      #if Types.collection?(value)
      if !Types.scalar?(value)
        #if done[value.__id__]
        #  rule2 = done[value.__id__]
        #  if rule2.is_a?(Rule)
        #    return if rule.equal?(rule2)
        #    done[value.__id__] = [rule2, rule]
        #  elsif rule2.is_a?(Array)
        #    return if rule2.any? {|r| r.equal?(rule)}
        #    done[value.__id__] << rule
        #  else
        #    raise "unreachable"
        #  end
        #end
        return if done[value.__id__]     # avoid infinite loop
        done[value.__id__] = rule
      end
      if rule.required && value.nil?
        #* key=:required_novalue  msg="value required but none."
        errors << validate_error(:required_novalue, rule, path, value)
        return
      end
      if rule.type_class && !value.nil? && !value.is_a?(rule.type_class)
        unless rule.classobj && value.is_a?(rule.classobj)
          #* key=:type_unmatch  msg="not a %s."
          errors << validate_error(:type_unmatch, rule, path, value, [Kwalify.word(rule.type)])
          return
        end
      end
      #
      n = errors.length
      if rule.sequence
        _validate_sequence(value, rule, path, errors, done, uniq_table, recursive)
      elsif rule.mapping
        _validate_mapping(value, rule, path, errors, done, uniq_table, recursive)
      else
        _validate_scalar(value, rule, path, errors, done, uniq_table)
      end
      return unless errors.length == n
      #
      #path_str = path.is_a?(Array) ? '/'+path.join('/') : path
      #validate_hook(value, rule, path_str, errors)
      #@block.call(value, rule, path_str, errors) if @block
      validate_hook(value, rule, path, errors)
      @block.call(value, rule, path, errors) if @block
    end


    private


    def _validate_sequence(list, seq_rule, path, errors, done, uniq_table, recursive=true)
      assert_error("seq_rule.sequence.class==#{seq_rule.sequence.class.name} (expected Array)") unless seq_rule.sequence.is_a?(Array)
      assert_error("seq_rule.sequence.length==#{seq_rule.sequence.length} (expected 1)") unless seq_rule.sequence.length == 1
      return if list.nil? || !recursive
      rule = seq_rule.sequence[0]
      uniq_table = rule._uniqueness_check_table()
      list.each_with_index do |val, i|
        child_path = path.is_a?(Array) ? path + [i] : "#{path}/#{i}"
        _validate(val, rule, child_path, errors, done, uniq_table)   ## validate recursively
      end
    end


    def _validate_mapping(hash, map_rule, path, errors, done, uniq_table, recursive=true)
      assert_error("map_rule.mapping.class==#{map_rule.mapping.class.name} (expected Hash)") unless map_rule.mapping.is_a?(Hash)
      return if hash.nil?
      return if !recursive
      _validate_mapping_required_keys(hash, map_rule, path, errors)
      hash.each do |key, val|
        rule = map_rule.mapping[key]
        child_path = path.is_a?(Array) ? path+[key] : "#{path}/#{key}"
        unless rule
          #* key=:key_undefined  msg="key '%s' is undefined."
          errors << validate_error(:key_undefined, rule, child_path, hash, ["#{key}:"])
          ##* key=:key_undefined  msg="undefined key."
          #errors << validate_error(:key_undefined, rule, child_path, "#{key}:")
        else
          _validate(val, rule, child_path, errors, done,
                    uniq_table ? uniq_table[key] : nil)   ## validate recursively
        end
      end
    end


    def _validate_mapping_required_keys(hash, map_rule, path, errors)  #:nodoc:
      map_rule.mapping.each do |key, rule|
        #next unless rule.required
        #val = hash.is_a?(Hash) ? hash[key] : hash.instance_variable_get("@#{key}")
        #if val.nil?
        if rule.required && hash[key].nil?  # or !hash.key?(key)
          #* key=:required_nokey  msg="key '%s:' is required."
          errors << validate_error(:required_nokey, rule, path, hash, [key])
        end
      end
    end
    public :_validate_mapping_required_keys


    def _validate_scalar(value, rule, path, errors, done, uniq_table)
      assert_error("rule.sequence.class==#{rule.sequence.class.name} (expected NilClass)") if rule.sequence
      assert_error("rule.mapping.class==#{rule.mapping.class.name} (expected NilClass)") if rule.mapping
      _validate_assert( value, rule, path, errors)  if rule.assert_proc
      _validate_enum(   value, rule, path, errors)  if rule.enum
      return if value.nil?
      _validate_pattern(value, rule, path, errors)  if rule.pattern
      _validate_range(  value, rule, path, errors)  if rule.range
      _validate_length( value, rule, path, errors)  if rule.length
      _validate_unique( value, rule, path, errors, uniq_table)  if uniq_table
    end


    def _validate_unique(value, rule, path, errors, uniq_table)
      assert_error "uniq_table=#{uniq_table.inspect}" unless rule.unique || rule.ident
      if uniq_table.key?(value)
        exist_at = uniq_table[value]
        exist_at = "/#{exist_at.join('/')}" if exist_at.is_a?(Array)
        #* key=:value_notunique  msg="is already used at '%s'."
        errors << validate_error(:value_notunique, rule, path, value, exist_at)
      else
        uniq_table[value] = path.dup
      end
    end
    public :_validate_unique


    def _validate_assert(value, rule, path, errors)
      assert_error("rule=#{rule._inspect}") unless rule.assert_proc
      unless rule.assert_proc.call(value)
        #* key=:assert_failed  msg="assertion expression failed (%s)."
        errors << validate_error(:assert_failed, rule, path, value, [rule.assert])
      end
    end


    def _validate_enum(value, rule, path, errors)
      assert_error("rule=#{rule._inspect}") unless rule.enum
      unless rule.enum.include?(value)
        keyname = path.is_a?(Array) ? path[-1] : File.basename(path)
        keyname = 'enum' if keyname =~ /\A\d+\z/
        #* key=:enum_notexist  msg="invalid %s value."
        errors << validate_error(:enum_notexist, rule, path, value, [keyname])
      end
    end


    def _validate_pattern(value, rule, path, errors)
      assert_error("rule=#{rule._inspect}") unless rule.pattern
      unless value.to_s =~ rule.regexp
        #* key=:pattern_unmatch  msg="not matched to pattern %s."
        errors << validate_error(:pattern_unmatch, rule, path, value, [rule.pattern])
      end
    end


    def _validate_range(value, rule, path, errors)
      assert_error("rule=#{rule._inspect}") unless rule.range
      assert_error("value.class=#{value.class.name}") unless Types.scalar?(value)
      h = rule.range
      max, min, max_ex, min_ex = h['max'], h['min'], h['max-ex'], h['min-ex']
      if max && max < value
        #* key=:range_toolarge  msg="too large (> max %s)."
        errors << validate_error(:range_toolarge, rule, path, value, [max.to_s])
      end
      if min && min > value
        #* key=:range_toosmall  msg="too small (< min %s)."
        errors << validate_error(:range_toosmall, rule, path, value, [min.to_s])
      end
      if max_ex && max_ex <= value
        #* key=:range_toolargeex  msg="too large (>= max %s)."
        errors << validate_error(:range_toolargeex, rule, path, value, [max_ex.to_s])
      end
      if min_ex && min_ex >= value
        #* key=:range_toosmallex  msg="too small (<= min %s)."
        errors << validate_error(:range_toosmallex, rule, path, value, [min_ex.to_s])
      end
    end


    def _validate_length(value, rule, path, errors)
      assert_error("rule=#{rule._inspect}") unless rule.length
      assert_error("value.class=#{value.class.name}") unless value.is_a?(String) || value.is_a?(Text)
      len = value.to_s.length
      h = rule.length
      max, min, max_ex, min_ex = h['max'], h['min'], h['max-ex'], h['min-ex']
      if max && max < len
        #* key=:length_toolong  msg="too long (length %d > max %d)."
        errors << validate_error(:length_toolong, rule, path, value, [len, max])
      end
      if min && min > len
        #* key=:length_tooshort  msg="too short (length %d < min %d)."
        errors << validate_error(:length_tooshort, rule, path, value, [len, min])
      end
      if max_ex && max_ex <= len
        #* key=:length_toolongex  msg="too long (length %d >= max %d)."
        errors << validate_error(:length_toolongex, rule, path, value, [len, max_ex])
      end
      if min_ex && min_ex >= len
        #* key=:length_tooshortex  msg="too short (length %d <= min %d)."
        errors << validate_error(:length_tooshortex, rule, path, value, [len, min_ex])
      end
    end


  end

end
