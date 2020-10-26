###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'kwalify/errors'
require 'kwalify/rule'
require 'kwalify/validator'
require 'kwalify/parser/yaml'
#require 'yaml'

module Kwalify


  ##
  ## ex.
  ##   meta_validator = Kwalify::MetaValidator.instance()
  ##   schema = File.load_file('schema.yaml')
  ##   errors = meta_validator.validate(schema)
  ##   if !errors.empty?
  ##     errors.each do |error|
  ##       puts "[#{error.path}] #{error.message}"
  ##     end
  ##   end
  ##
  class MetaValidator < Validator

    filename = File.join(File.dirname(__FILE__), 'kwalify.schema.yaml')
    META_SCHEMA = File.read(filename)

    def self.instance()
      unless @instance
        schema = Kwalify::Yaml::Parser.new().parse(META_SCHEMA)
        @instance = MetaValidator.new(schema)
      end
      return @instance
    end

    def initialize(schema, &block)
      super
    end

    def validate_hook(value, rule, path, errors)
      return if value.nil?    ## realy?
      return unless rule.name == "MAIN"
      #
      hash = value
      type = hash['type']
      type = Types::DEFAULT_TYPE if type.nil?
      klass = Types.type_class(type)
      #unless klass
      #  errors << validate_error(:type_unknown, rule, "#{path}/type", type)
      #end
      #
      if hash.key?('class')
        val = hash['class']
        unless val.nil? || type == 'map'
          errors << validate_error(:class_notmap, rule, "#{path}/class", 'class:')
        end
      end
      #
      if hash.key?('pattern')
        val = hash['pattern']
        pat = (val =~ /\A\/(.*)\/([mi]?[mi]?)\z/ ? $1 : val)
        begin
          Regexp.compile(pat)
        rescue RegexpError => ex
          errors << validate_error(:pattern_syntaxerr, rule, "#{path}/pattern", val)
        end
      end
      #
      if hash.key?('enum')
        if Types.collection_type?(type)
          errors << validate_error(:enum_notscalar, rule, path, 'enum:')
        else
          #elem_table = {}
          hash['enum'].each do |elem|
            #if elem_table[elem]
            #  errors << validate_error(:enum_duplicate, rule, "#{path}/enum", elem.to_s)
            #end
            #elem_table[elem] = true
            unless elem.is_a?(klass)
              errors << validate_error(:enum_type_unmatch, rule, "#{path}/enum", elem, [Kwalify.word(type)])
            end
          end
        end
      end
      #
      if hash.key?('assert')
        val =  hash['assert']
        #val =~ /\bval\b/ or errors << validate_error(:assert_noval, rule, "#{path}/assert", val)
        begin
          eval "proc { |val| #{val} }"
        rescue ::SyntaxError => ex
          errors << validate_error(:assert_syntaxerr, rule, "#{path}/assert", val)
        end
      end
      #
      if hash.key?('range')
        val = hash['range']
        curr_path = path + "/range"
        #if ! val.is_a?(Hash)
        #  errors << validate_error(:range_notmap, rule, curr_path, val)
        #elsif ...
        if Types.collection_type?(type) || type == 'bool' || type == 'any'
          errors << validate_error(:range_notscalar, rule, path, 'range:')
        else
          val.each do |rkey, rval|
            #case rkey
            #when 'max', 'min', 'max-ex', 'min-ex'
              unless rval.is_a?(klass)
                typename = Kwalify.word(type) || type
                errors << validate_error(:range_type_unmatch, rule, "#{curr_path}/#{rkey}", rval, [typename])
              end
            #else
            #  errors << validate_error(:range_undefined, rule, curr_path, "#{rkey}:")
            #end
          end
        end
        if val.key?('max') && val.key?('max-ex')
          errors << validate_error(:range_twomax, rule, curr_path, nil)
        end
        if val.key?('min') && val.key?('min-ex')
          errors << validate_error(:range_twomin, rule, curr_path, nil)
        end
        max, min, max_ex, min_ex = val['max'], val['min'], val['max-ex'], val['min-ex']
        if max
          if min && max < min
            errors << validate_error(:range_maxltmin, rule, curr_path, nil, [max, min])
          elsif min_ex && max <= min_ex
            errors << validate_error(:range_maxleminex, rule, curr_path, nil, [max, min_ex])
          end
        elsif max_ex
          if min && max_ex <= min
            errors << validate_error(:range_maxexlemin, rule, curr_path, nil, [max_ex, min])
          elsif min_ex && max_ex <= min_ex
            errors << validate_error(:range_maxexleminex, rule, curr_path, nil, [max_ex, min_ex])
          end
        end
      end
      #
      if hash.key?('length')
        val = hash['length']
        curr_path = path + "/length"
        #val.is_a?(Hash) or errors << validate_error(:length_notmap, rule, curr_path, val)
        unless type == 'str' || type == 'text'
          errors << validate_error(:length_nottext, rule, path, 'length:')
        end
        #val.each do |lkey, lval|
        #  #case lkey
        #  #when 'max', 'min', 'max-ex', 'min-ex'
        #    unless lval.is_a?(Integer)
        #      errors << validate_error(:length_notint, rule, "#{curr_path}/#{lkey}", lval)
        #    end
        #  #else
        #  #  errors << validate_error(:length_undefined, rule, curr_path, "#{lkey}:")
        #  #end
        #end
        if val.key?('max') && val.key?('max-ex')
          errors << validate_error(:length_twomax, rule, curr_path, nil)
        end
        if val.key?('min') && val.key?('min-ex')
          errors << validate_error(:length_twomin, rule, curr_path, nil)
        end
        max, min, max_ex, min_ex = val['max'], val['min'], val['max-ex'], val['min-ex']
        if max
          if min && max < min
            errors << validate_error(:length_maxltmin, rule, curr_path, nil, [max, min])
          elsif min_ex && max <= min_ex
            errors << validate_error(:length_maxleminex, rule, curr_path, nil, [max, min_ex])
          end
        elsif max_ex
          if min && max_ex <= min
            errors << validate_error(:length_maxexlemin, rule, curr_path, nil, [max_ex, min])
          elsif min_ex && max_ex <= min_ex
            errors << validate_error(:length_maxexleminex, rule, curr_path, nil, [max_ex, min_ex])
          end
        end
      end
      #
      if hash.key?('unique')
        if hash['unique'] && Types.collection_type?(type)
          errors << validate_error(:unique_notscalar, rule, path, "unique:")
        end
        if path.empty?
          errors << validate_error(:unique_onroot, rule, "/", "unique:")
        end
      end
      #
      if hash.key?('ident')
        if hash['ident'] && Types.collection_type?(type)
          errors << validate_error(:ident_notscalar, rule, path, "ident:")
        end
        if path.empty?
          errors << validate_error(:ident_onroot, rule, "/", "ident:")
        end
      end
      #
      if hash.key?('default')
        val = hash['default']
        if Types.collection_type?(type)
          errors << validate_error(:default_notscalar, rule, path, "default:")
        elsif !val.nil? && !val.is_a?(klass)
          errors << validate_error(:default_unmatch, rule, "#{path}/default", val, [Kwalify.word(type)])
        end
      end
      #
      if hash.key?('sequence')
        val = hash['sequence']
        #if !val.nil? && !val.is_a?(Array)
        #  errors << validate_error(:sequence_notseq,  rule, "#{path}/sequence", val)
        #elsif ...
        if val.nil? || val.empty?
          errors << validate_error(:sequence_noelem,  rule, "#{path}/sequence", val)
        elsif val.length > 1
          errors << validate_error(:sequence_toomany, rule, "#{path}/sequence", val)
        else
          elem = val[0]
          assert_error("elem.class=#{elem.class}") unless elem.is_a?(Hash)
          if elem['ident'] && elem['type'] != 'map'
            errors << validate_error(:ident_notmap, nil, "#{path}/sequence/0", 'ident:')
          end
        end
      end
      #
      if hash.key?('mapping')
        val = hash['mapping']
        if !val.nil? && !val.is_a?(Hash)
          errors << validate_error(:mapping_notmap, rule, "#{path}/mapping", val)
        elsif val.nil? || (val.empty? && !val.default)
          errors << validate_error(:mapping_noelem, rule, "#{path}/mapping", val)
        end
      end
      #
      if type == 'seq'
        errors << validate_error(:seq_nosequence, rule, path, nil)    unless hash.key?('sequence')
        #errors << validate_error(:seq_conflict, rule, path, 'enum:')      if hash.key?('enum')
        errors << validate_error(:seq_conflict, rule, path, 'pattern:')    if hash.key?('pattern')
        errors << validate_error(:seq_conflict, rule, path, 'mapping:')    if hash.key?('mapping')
        #errors << validate_error(:seq_conflict, rule, path, 'range:')     if hash.key?('range')
        #errors << validate_error(:seq_conflict, rule, path, 'length:')    if hash.key?('length')
      elsif type == 'map'
        errors << validate_error(:map_nomapping, rule, path, nil)     unless hash.key?('mapping')
        #errors << validate_error(:map_conflict, rule, path, 'enum:')      if hash.key?('enum')
        errors << validate_error(:map_conflict, rule, path, 'pattern:')    if hash.key?('pattern')
        errors << validate_error(:map_conflict, rule, path, 'sequence:')   if hash.key?('sequence')
        #errors << validate_error(:map_conflict, rule, path, 'range:')     if hash.key?('range')
        #errors << validate_error(:map_conflict, rule, path, 'length:')    if hash.key?('length')
      else
        errors << validate_error(:scalar_conflict, rule, path, 'sequence:') if hash.key?('sequence')
        errors << validate_error(:scalar_conflict, rule, path, 'mapping:')  if hash.key?('mapping')
        if hash.key?('enum')
          errors << validate_error(:enum_conflict, rule, path, 'range:')  if hash.key?('range')
          errors << validate_error(:enum_conflict, rule, path, 'length:')  if hash.key?('length')
          errors << validate_error(:enum_conflict, rule, path, 'pattern:') if hash.key?('pattern')
        end
        if hash.key?('default')
          errors << validate_error(:default_conflict, rule, path, 'default:') if hash['required']
        end
      end

    end  # end of def validate_hook()


  end # end of class MetaValidator


  META_VALIDATOR = MetaValidator.instance()

  def self.meta_validator        # obsolete
    return META_VALIDATOR
  end

end
