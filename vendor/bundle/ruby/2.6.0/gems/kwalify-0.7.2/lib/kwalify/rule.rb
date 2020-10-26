###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'kwalify/messages'
require 'kwalify/errors'
require 'kwalify/types'


module Kwalify


  class Rule
    include Kwalify::ErrorHelper

    attr_accessor :parent
    attr_reader :name
    attr_reader :desc
    attr_reader :enum
    attr_reader :required
    attr_reader :type
    attr_reader :type_class
    attr_reader :pattern
    attr_reader :regexp
    attr_reader :sequence
    attr_reader :mapping
    attr_reader :assert
    attr_reader :assert_proc
    attr_reader :range
    attr_reader :length
    attr_reader :ident
    attr_reader :unique
    attr_reader :default
    attr_reader :classname
    attr_reader :classobj


    def initialize(hash=nil, parent=nil)
      _init(hash, "", {}) if hash
      @parent = parent
    end


    def _init(hash, path="", rule_table={})
      unless hash.is_a?(Hash)
        #* key=:schema_notmap  msg="schema definition is not a mapping."
        raise Kwalify.schema_error(:schema_notmap, nil, (!path || path.empty? ? "/" : path), nil)
      end
      rule = self
      rule_table[hash.__id__] = rule
      ## 'type:' entry
      curr_path = "#{path}/type"
      _init_type_value(hash['type'], rule, curr_path)
      ## other entries
      hash.each do |key, val|
        curr_path = "#{path}/#{key}"
        sym = key.intern
        method = get_init_method(sym)
        unless method
          #* key=:key_unknown  msg="unknown key."
          raise schema_error(:key_unknown, rule, curr_path, "#{key}:")
        end
        if sym == :sequence || sym == :mapping
          __send__(method, val, rule, curr_path, rule_table)
        else
          __send__(method, val, rule, curr_path)
        end
      end
      _check_confliction(hash, rule, path)
      return self
    end


    keys = %w[type name desc required pattern enum assert range length
              ident unique default sequence mapping class]
    #table = keys.inject({}) {|h, k| h[k.intern] = "_init_#{k}_value".intern; h }
    table = {}; keys.each {|k| table[k.intern] = "_init_#{k}_value".intern }
    @@dispatch_table = table


    protected


    def get_init_method(sym)
      @_dispatch_table ||= @@dispatch_table
      return @_dispatch_table[sym]
    end


    private


    def _init_type_value(val, rule, path)
      @type = val
      @type = Types::DEFAULT_TYPE if @type.nil?
      unless @type.is_a?(String)
        #* key=:type_notstr  msg="not a string."
        raise schema_error(:type_notstr, rule, path, @type.to_s)
      end
      @type_class = Types.type_class(@type)
      #if @type_class.nil?
      #  begin
      #    @type_class = Kernel.const_get(@type)
      #  rescue NameError
      #  end
      #end
      unless @type_class
        #* key=:type_unknown  msg="unknown type."
        raise schema_error(:type_unknown, rule, path, @type.to_s)
      end
    end


    def _init_class_value(val, rule, path)
      @classname = val
      unless @type == 'map'
        #* key=:class_notmap  msg="available only with map type."
        raise schema_error(:class_notmap, rule, path, 'class:')
      end
      begin
        @classobj = Util.get_class(val)
      rescue NameError
        @classobj = nil
      end
    end


    def _init_name_value(val, rule, path)
      @name = val
    end


    def _init_desc_value(val, rule, path)
      @desc = val
    end


    def _init_required_value(val, rule, path)
      @required = val
      unless val.is_a?(Boolean)  #|| val.nil?
        #* key=:required_notbool  msg="not a boolean."
        raise schema_error(:required_notbool, rule, path, val)
      end
    end


    def _init_pattern_value(val, rule, path)
      @pattern = val
      unless val.is_a?(String) || val.is_a?(Regexp)
        #* key=:pattern_notstr  msg="not a string (or regexp)"
        raise schema_error(:pattern_notstr, rule, path, val)
      end
      unless val =~ /\A\/(.*)\/([mi]?[mi]?)\z/
        #* key=:pattern_notmatch  msg="should be '/..../'."
        raise schema_error(:pattern_notmatch, rule, path, val)
      end
      pat = $1; opt = $2
      flag = 0
      flag += Regexp::IGNORECASE if opt.include?("i")
      flag += Regexp::MULTILINE  if opt.include?("m")
      begin
        @regexp = Regexp.compile(pat, flag)
      rescue RegexpError => ex
        #* key=:pattern_syntaxerr  msg="has regexp error."
        raise schema_error(:pattern_syntaxerr, rule, path, val)
      end
    end


    def _init_enum_value(val, rule, path)
      @enum = val
      unless val.is_a?(Array)
        #* key=:enum_notseq  msg="not a sequence."
        raise schema_error(:enum_notseq, rule, path, val)
      end
      if Types.collection_type?(@type)  # unless Kwalify.scalar_class?(@type_class)
        #* key=:enum_notscalar  msg="not available with seq or map."
        raise schema_error(:enum_notscalar, rule, File.dirname(path), 'enum:')
      end
      elem_table = {}
      @enum.each do |elem|
        unless elem.is_a?(@type_class)
          #* key=:enum_type_unmatch  msg="%s type expected."
          raise schema_error(:enum_type_unmatch, rule, path, elem, [Kwalify.word(@type)])
        end
        if elem_table[elem]
          #* key=:enum_duplicate  msg="duplicated enum value."
          raise schema_error(:enum_duplicate, rule, path, elem.to_s)
        end
        elem_table[elem] = true
      end
    end


    def _init_assert_value(val, rule, path)
      @assert = val
      unless val.is_a?(String)
        #* key=:assert_notstr  msg="not a string."
        raise schema_error(:assert_notstr, rule, path, val)
      end
      unless val =~ /\bval\b/
        #* key=:assert_noval  msg="'val' is not used."
        raise schema_error(:assert_noval, rule, path, val)
      end
      begin
        @assert_proc = eval "proc { |val| #{val} }"
      rescue ::SyntaxError => ex
        #* key=:assert_syntaxerr  msg="expression syntax error."
        raise schema_error(:assert_syntaxerr, rule, path, val)
      end
    end


    def _init_range_value(val, rule, path)
      @range = val
      unless val.is_a?(Hash)
        #* key=:range_notmap  msg="not a mapping."
        raise schema_error(:range_notmap, rule, path, val)
      end
      if Types.collection_type?(@type) || @type == 'bool'
        #* key=:range_notscalar  msg="is available only with scalar type."
        raise schema_error(:range_notscalar, rule, File.dirname(path), 'range:')
      end
      val.each do |k, v|
        case k
        when 'max', 'min', 'max-ex', 'min-ex'
          unless v.is_a?(@type_class)
            typename = Kwalify.word(@type) || @type
            #* key=:range_type_unmatch  msg="not a %s."
            raise schema_error(:range_type_unmatch, rule, "#{path}/#{k}", v, [typename])
          end
        else
          #* key=:range_undefined  msg="undefined key."
          raise schema_error(:range_undefined, rule, "#{path}/#{k}", "#{k}:")
        end
      end
      if val.key?('max') && val.key?('max-ex')
        #* key=:range_twomax  msg="both 'max' and 'max-ex' are not available at once."
        raise schema_error(:range_twomax, rule, path, nil)
      end
      if val.key?('min') && val.key?('min-ex')
        #* key=:range_twomin  msg="both 'min' and 'min-ex' are not available at once."
        raise schema_error(:range_twomin, rule, path, nil)
      end
      max, min, max_ex, min_ex = val['max'], val['min'], val['max-ex'], val['min-ex']
      if max
        if min && max < min
          #* key=:range_maxltmin  msg="max '%s' is less than min '%s'."
          raise validate_error(:range_maxltmin, rule, path, nil, [max, min])
        elsif min_ex && max <= min_ex
          #* key=:range_maxleminex  msg="max '%s' is less than or equal to min-ex '%s'."
          raise validate_error(:range_maxleminex, rule, path, nil, [max, min_ex])
        end
      elsif max_ex
        if min && max_ex <= min
          #* key=:range_maxexlemin msg="max-ex '%s' is less than or equal to min '%s'."
          raise validate_error(:range_maxexlemin, rule, path, nil, [max_ex, min])
        elsif min_ex && max_ex <= min_ex
          #* key=:range_maxexleminex msg="max-ex '%s' is less than or equal to min-ex '%s'."
          raise validate_error(:range_maxexleminex, rule, path, nil, [max_ex, min_ex])
        end
      end
    end


    def _init_length_value(val, rule, path)
      @length = val
      unless val.is_a?(Hash)
        #* key=:length_notmap  msg="not a mapping."
        raise schema_error(:length_notmap, rule, path, val)
      end
      unless @type == 'str' || @type == 'text'
        #* key=:length_nottext  msg="is available only with string or text."
        raise schema_error(:length_nottext, rule, File.dirname(path), 'length:')
      end
      val.each do |k, v|
        case k
        when 'max', 'min', 'max-ex', 'min-ex'
          unless v.is_a?(Integer)
            #* key=:length_notint  msg="not an integer."
            raise schema_error(:length_notint, rule, "#{path}/#{k}", v)
          end
        else
          #* key=:length_undefined  msg="undefined key."
          raise schema_error(:length_undefined, rule, "#{path}/#{k}", "#{k}:")
        end
      end
      if val.key?('max') && val.key?('max-ex')
        #* key=:length_twomax msg="both 'max' and 'max-ex' are not available at once."
        raise schema_error(:length_twomax, rule, path, nil)
      end
      if val.key?('min') && val.key?('min-ex')
        #* key=:length_twomin msg="both 'min' and 'min-ex' are not available at once."
        raise schema_error(:length_twomin, rule, path, nil)
      end
      max, min, max_ex, min_ex = val['max'], val['min'], val['max-ex'], val['min-ex']
      if max
        if min && max < min
          #* key=:length_maxltmin  msg="max '%s' is less than min '%s'."
          raise validate_error(:length_maxltmin, rule, path, nil, [max, min])
        elsif min_ex && max <= min_ex
          #* key=:length_maxleminex  msg="max '%s' is less than or equal to min-ex '%s'."
          raise validate_error(:length_maxleminex, rule, path, nil, [max, min_ex])
        end
      elsif max_ex
        if min && max_ex <= min
          #* key=:length_maxexlemin  msg="max-ex '%s' is less than or equal to min '%s'."
          raise validate_error(:length_maxexlemin, rule, path, nil, [max_ex, min])
        elsif min_ex && max_ex <= min_ex
          #* key=:length_maxexleminex  msg="max-ex '%s' is less than or equal to min-ex '%s'."
          raise validate_error(:length_maxexleminex, rule, path, nil, [max_ex, min_ex])
        end
      end
    end


    def _init_ident_value(val, rule, path)
      @ident = val
      @required = true
      unless val.is_a?(Boolean)
        #* key=:ident_notbool  msg="not a boolean."
        raise schema_error(:ident_notbool, rule, path, val)
      end
      if @type == 'map' || @type == 'seq'
        #* key=:ident_notscalar  msg="is available only with a scalar type."
        raise schema_error(:ident_notscalar, rule, File.dirname(path), "ident:")
      end
      if File.dirname(path) == "/"
        #* key=:ident_onroot  msg="is not available on root element."
        raise schema_error(:ident_onroot, rule, "/", "ident:")
      end
      unless @parent && @parent.type == 'map'
        #* key=:ident_notmap  msg="is available only with an element of mapping."
        raise schema_error(:ident_notmap, rule, File.dirname(path), "ident:")
      end
    end


    def _init_unique_value(val, rule, path)
      @unique = val
      unless val.is_a?(Boolean)
        #* key=:unique_notbool  msg="not a boolean."
        raise schema_error(:unique_notbool, rule, path, val)
      end
      if @type == 'map' || @type == 'seq'
        #* key=:unique_notscalar  msg="is available only with a scalar type."
        raise schema_error(:unique_notscalar, rule, File.dirname(path), "unique:")
      end
      if File.dirname(path) == "/"
        #* key=:unique_onroot  msg="is not available on root element."
        raise schema_error(:unique_onroot, rule, "/", "unique:")
      end
    end


    def _init_default_value(val, rule, path)
      @default = val
      unless Types.scalar?(val)
        #* key=:default_nonscalarval  msg="not a scalar."
        raise schema_error(:default_nonscalarval, rule, path, val)
      end
      if @type == 'map' || @type == 'seq'
        #* key=:default_notscalar  msg="is available only with a scalar type."
        raise schema_error(:default_notscalar, rule, File.dirname(path), "default:")
      end
      unless val.nil? || val.is_a?(@type_class)
        #* key=:default_unmatch  msg="not a %s."
        raise schema_error(:default_unmatch, rule, path, val, [Kwalify.word(@type)])
      end
    end


    def _init_sequence_value(val, rule, path, rule_table)
      if !val.nil? && !val.is_a?(Array)
        #* key=:sequence_notseq  msg="not a sequence."
        raise schema_error(:sequence_notseq, rule, path, val)
      elsif val.nil? || val.empty?
        #* key=:sequence_noelem  msg="required one element."
        raise schema_error(:sequence_noelem, rule, path, val)
      elsif val.length > 1
        #* key=:sequence_toomany  msg="required just one element."
        raise schema_error(:sequence_toomany, rule, path, val)
      else
        elem = val[0]
        elem ||= {}
        i = 0  # or 1?  *index*
        rule = rule_table[elem.__id__]
        rule ||= Rule.new(nil, self)._init(elem, "#{path}/#{i}", rule_table)
        @sequence = [ rule ]
      end
    end


    def _init_mapping_value(val, rule, path, rule_table)
      if !val.nil? && !val.is_a?(Hash)
        #* key=:mapping_notmap  msg="not a mapping."
        raise schema_error(:mapping_notmap, rule, path, val)
      elsif val.nil? || (val.empty? && !val.default)
        #* key=:mapping_noelem  msg="required at least one element."
        raise schema_error(:mapping_noelem, rule, path, val)
      else
        @mapping = {}
        if val.default
          elem = val.default  # hash
          rule = rule_table[elem.__id__]
          rule ||= Rule.new(nil, self)._init(elem, "#{path}/=", rule_table)
          @mapping.default = rule
        end
        val.each do |k, v|
          ##* key=:key_duplicate  msg="key duplicated."
          #raise schema_error(:key_duplicate, rule, path, key) if @mapping.key?(key)
          v ||= {}
          rule = rule_table[v.__id__]
          rule ||= Rule.new(nil, self)._init(v, "#{path}/#{k}", rule_table)
          if k == '='
            @mapping.default = rule
          else
            @mapping[k] = rule
          end
        end if val
      end
    end


    def _check_confliction(hash, rule, path)
      if @type == 'seq'
        #* key=:seq_nosequence  msg="type 'seq' requires 'sequence:'."
        raise schema_error(:seq_nosequence, rule, path, nil) unless hash.key?('sequence')
        #* key=:seq_conflict  msg="not available with sequence."
        raise schema_error(:seq_conflict, rule, path, 'enum:')      if @enum
        raise schema_error(:seq_conflict, rule, path, 'pattern:')   if @pattern
        raise schema_error(:seq_conflict, rule, path, 'mapping:')   if @mapping
        raise schema_error(:seq_conflict, rule, path, 'range:')     if @range
        raise schema_error(:seq_conflict, rule, path, 'length:')    if @length
      elsif @type == 'map'
        #* key=:map_nomapping  msg="type 'map' requires 'mapping:'."
        raise schema_error(:map_nomapping, rule, path, nil)  unless hash.key?('mapping')
        #* key=:map_conflict  msg="not available with mapping."
        raise schema_error(:map_conflict, rule, path, 'enum:')      if @enum
        raise schema_error(:map_conflict, rule, path, 'pattern:')   if @pattern
        raise schema_error(:map_conflict, rule, path, 'sequence:')  if @sequence
        raise schema_error(:map_conflict, rule, path, 'range:')     if @range
        raise schema_error(:map_conflict, rule, path, 'length:')    if @length
      else
        #* key=:scalar_conflict  msg="not available with scalar type."
        raise schema_error(:scalar_conflict, rule, path, 'sequence:') if @sequence
        raise schema_error(:scalar_conflict, rule, path, 'mapping:')  if @mapping
        if @enum
          #* key=:enum_conflict  msg="not available with 'enum:'."
          raise schema_error(:enum_conflict, rule, path, 'range:')   if @range
          raise schema_error(:enum_conflict, rule, path, 'length:')  if @length
          raise schema_error(:enum_conflict, rule, path, 'pattern:') if @pattern
        end
        unless @default.nil?
          #* key=:default_conflict  msg="not available when 'required:' is true."
          raise schema_error(:default_conflict, rule, path, 'default:') if @required
        end
      end
    end

    #def inspect()
    #  str = "";  level = 0;  done = {}
    #  _inspect(str, level, done)
    #  return str
    #end


    protected


    def _inspect(str="", level=0, done={})
      done[self.__id__] = true
      str << "  " * level << "name:    #{@name}\n"         unless @name.nil?
      str << "  " * level << "desc:    #{@desc}\n"         unless @desc.nil?
      str << "  " * level << "type:    #{@type}\n"         unless @type.nil?
      str << "  " * level << "klass:    #{@type_class.name}\n"  unless @type_class.nil?
      str << "  " * level << "required:  #{@required}\n"      unless @required.nil?
      str << "  " * level << "pattern:  #{@regexp.inspect}\n"  unless @pattern.nil?
      str << "  " * level << "assert:   #{@assert}\n"        unless @assert.nil?
      str << "  " * level << "ident:    #{@ident}\n"        unless @ident.nil?
      str << "  " * level << "unique:   #{@unique}\n"        unless @unique.nil?
      if !@enum.nil?
        str << "  " * level << "enum:\n"
        @enum.each do |item|
          str << "  " * (level+1) << "- #{item}\n"
        end
      end
      if !@range.nil?
        str << "  " * level
        str << "range:    { "
        colon = ""
        %w[max max-ex min min-ex].each do |key|
          val = @range[key]
          unless val.nil?
            str << colon << "#{key}: #{val.inspect}"
            colon = ", "
          end
        end
        str << " }\n"
      end
      if !@length.nil?
        str << "  " * level
        str << "length:    { "
        colon = ""
        %w[max max-ex min min-ex].each do |key|
          val = @length[key]
          if !val.nil?
            str << colon << "#{key}: #{val.inspect}"
            colon = ", "
          end
        end
        str << " }\n"
      end
      @sequence.each do |rule|
        if done[rule.__id__]
          str << "  " * (level+1) << "- ...\n"
        else
          str << "  " * (level+1) << "- \n"
          rule._inspect(str, level+2, done)
        end
      end if @sequence
      @mapping.each do |key, rule|
        if done[rule.__id__]
          str << '  ' * (level+1) << '"' << key << "\": ...\n"
        else
          str << '  ' * (level+1) << '"' << key << "\":\n"
          rule._inspect(str, level+2, done)
        end
      end if @mapping
      return str
    end


    public


    def _uniqueness_check_table()   # :nodoc:
      uniq_table = nil
      if @type == 'map'
        @mapping.keys.each do |key|
          rule = @mapping[key]
          if rule.unique || rule.ident
            uniq_table ||= {}
            uniq_table[key] = {}
          end
        end
      elsif @unique || @ident
        uniq_table = {}
      end
      return uniq_table
    end


  end


end
