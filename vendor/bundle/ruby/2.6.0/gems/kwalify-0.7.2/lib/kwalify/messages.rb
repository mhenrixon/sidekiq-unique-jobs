###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

module Kwalify

   @@messages = {}

   def self.msg(key)
      return @@messages[key]
   end



   @@messages[:command_help] = <<END
kwalify - schema validator and data binding tool for YAML and JSON
## Usage1: validate yaml document
kwalify [..options..] -f schema.yaml doc.yaml [doc2.yaml ...]
## Usage2: validate schema definition
kwalify [..options..] -m schema.yaml [schema2.yaml ...]
## Usage3: do action
kwalify [..options..] -a action -f schema.yaml [schema2.yaml ...]
  -h, --help     : help
  -v             : version
  -q             : quiet
  -s             : silent (obsolete, use '-q' instead)
  -f schema.yaml : schema definition file
  -m             : meta-validation mode
  -t             : expand tab characters
  -l             : show linenumber when errored (experimental)
  -E             : show errors in emacs-style (experimental, implies '-l')
  -a action      : action ('genclass-ruby', 'genclass-php', 'genclass-java')
                   (try '-ha genclass-ruby' for details)
  -I path        : template path (for '-a')
  -P             : allow preceding alias
END
#  -z              :  syntax checking of schema file
#  -I path         :  path for template of action



   ##----- begin
   # filename: lib/kwalify/main.rb
   @@messages[:command_option_actionnoschema] = "schema filename is not specified."
   @@messages[:command_option_noaction] = "command-line option '-f' or '-m' required."
   @@messages[:command_option_notemplate] = "%s: invalid action (template not found).\n"
   @@messages[:schema_empty]         = "%s: empty schema.\n"
   @@messages[:validation_empty]     = "%s#%d: empty."
   @@messages[:validation_empty]     = "%s#%d: empty.\n"
   @@messages[:validation_valid]     = "%s#%d: valid."
   @@messages[:command_option_schema_required] = "-%s: schema filename required."
   @@messages[:command_option_action_required] = "-%s: action required."
   @@messages[:command_option_tpath_required] = "-%s: template path required."
   @@messages[:command_property_invalid] = "%s: invalid property."
   @@messages[:command_option_invalid] = "-%s: invalid command option."
   # --
   # filename: lib/kwalify/rule.rb
   @@messages[:schema_notmap]        = "schema definition is not a mapping."
   @@messages[:key_unknown]          = "unknown key."
   @@messages[:type_notstr]          = "not a string."
   @@messages[:type_unknown]         = "unknown type."
   @@messages[:class_notmap]         = "available only with map type."
   @@messages[:required_notbool]     = "not a boolean."
   @@messages[:pattern_notstr]       = "not a string (or regexp)"
   @@messages[:pattern_notmatch]     = "should be '/..../'."
   @@messages[:pattern_syntaxerr]    = "has regexp error."
   @@messages[:enum_notseq]          = "not a sequence."
   @@messages[:enum_notscalar]       = "not available with seq or map."
   @@messages[:enum_type_unmatch]    = "%s type expected."
   @@messages[:enum_duplicate]       = "duplicated enum value."
   @@messages[:assert_notstr]        = "not a string."
   @@messages[:assert_noval]         = "'val' is not used."
   @@messages[:assert_syntaxerr]     = "expression syntax error."
   @@messages[:range_notmap]         = "not a mapping."
   @@messages[:range_notscalar]      = "is available only with scalar type."
   @@messages[:range_type_unmatch]   = "not a %s."
   @@messages[:range_undefined]      = "undefined key."
   @@messages[:range_twomax]         = "both 'max' and 'max-ex' are not available at once."
   @@messages[:range_twomin]         = "both 'min' and 'min-ex' are not available at once."
   @@messages[:range_maxltmin]       = "max '%s' is less than min '%s'."
   @@messages[:range_maxleminex]     = "max '%s' is less than or equal to min-ex '%s'."
   @@messages[:range_maxexlemin]     = "max-ex '%s' is less than or equal to min '%s'."
   @@messages[:range_maxexleminex]   = "max-ex '%s' is less than or equal to min-ex '%s'."
   @@messages[:length_notmap]        = "not a mapping."
   @@messages[:length_nottext]       = "is available only with string or text."
   @@messages[:length_notint]        = "not an integer."
   @@messages[:length_undefined]     = "undefined key."
   @@messages[:length_twomax]        = "both 'max' and 'max-ex' are not available at once."
   @@messages[:length_twomin]        = "both 'min' and 'min-ex' are not available at once."
   @@messages[:length_maxltmin]      = "max '%s' is less than min '%s'."
   @@messages[:length_maxleminex]    = "max '%s' is less than or equal to min-ex '%s'."
   @@messages[:length_maxexlemin]    = "max-ex '%s' is less than or equal to min '%s'."
   @@messages[:length_maxexleminex]  = "max-ex '%s' is less than or equal to min-ex '%s'."
   @@messages[:ident_notbool]        = "not a boolean."
   @@messages[:ident_notscalar]      = "is available only with a scalar type."
   @@messages[:ident_onroot]         = "is not available on root element."
   @@messages[:ident_notmap]         = "is available only with an element of mapping."
   @@messages[:unique_notbool]       = "not a boolean."
   @@messages[:unique_notscalar]     = "is available only with a scalar type."
   @@messages[:unique_onroot]        = "is not available on root element."
   @@messages[:default_nonscalarval] = "not a scalar."
   @@messages[:default_notscalar]    = "is available only with a scalar type."
   @@messages[:default_unmatch]      = "not a %s."
   @@messages[:sequence_notseq]      = "not a sequence."
   @@messages[:sequence_noelem]      = "required one element."
   @@messages[:sequence_toomany]     = "required just one element."
   @@messages[:mapping_notmap]       = "not a mapping."
   @@messages[:mapping_noelem]       = "required at least one element."
   @@messages[:seq_nosequence]       = "type 'seq' requires 'sequence:'."
   @@messages[:seq_conflict]         = "not available with sequence."
   @@messages[:map_nomapping]        = "type 'map' requires 'mapping:'."
   @@messages[:map_conflict]         = "not available with mapping."
   @@messages[:scalar_conflict]      = "not available with scalar type."
   @@messages[:enum_conflict]        = "not available with 'enum:'."
   @@messages[:default_conflict]     = "not available when 'required:' is true."
   # --
   # filename: lib/kwalify/validator.rb
   @@messages[:required_novalue]     = "value required but none."
   @@messages[:type_unmatch]         = "not a %s."
   @@messages[:key_undefined]        = "key '%s' is undefined."
   @@messages[:required_nokey]       = "key '%s:' is required."
   @@messages[:value_notunique]      = "is already used at '%s'."
   @@messages[:assert_failed]        = "assertion expression failed (%s)."
   @@messages[:enum_notexist]        = "invalid %s value."
   @@messages[:pattern_unmatch]      = "not matched to pattern %s."
   @@messages[:range_toolarge]       = "too large (> max %s)."
   @@messages[:range_toosmall]       = "too small (< min %s)."
   @@messages[:range_toolargeex]     = "too large (>= max %s)."
   @@messages[:range_toosmallex]     = "too small (<= min %s)."
   @@messages[:length_toolong]       = "too long (length %d > max %d)."
   @@messages[:length_tooshort]      = "too short (length %d < min %d)."
   @@messages[:length_toolongex]     = "too long (length %d >= max %d)."
   @@messages[:length_tooshortex]    = "too short (length %d <= min %d)."
   # --
   # filename: lib/kwalify/yaml-parser.rb
   @@messages[:flow_hastail]         = "flow style sequence is closed but got '%s'."
   @@messages[:flow_eof]             = "found EOF when parsing flow style."
   @@messages[:flow_alias_label]     = "alias name expected."
   @@messages[:flow_anchor_label]    = "anchor name expected."
   @@messages[:flow_noseqitem]       = "sequence item required (or last comma is extra)."
   @@messages[:flow_seqnotclosed]    = "flow style sequence requires ']'."
   @@messages[:flow_mapnoitem]       = "mapping item required (or last comma is extra)."
   @@messages[:flow_mapnotclosed]    = "flow style mapping requires '}'."
   @@messages[:flow_nocolon]         = "':' expected but got %s."
   @@messages[:flow_str_notclosed]   = "%s: string not closed."
   @@messages[:anchor_duplicated]    = "anchor '%s' is already used."
   @@messages[:alias_extradata]      = "alias cannot take any data."
   @@messages[:anchor_notfound]      = "anchor '%s' not found"
   @@messages[:sequence_noitem]      = "sequence item is expected."
   @@messages[:sequence_badindent]   = "illegal indent of sequence."
   @@messages[:mapping_noitem]       = "mapping item is expected."
   @@messages[:mapping_badindent]    = "illegal indent of mapping."
   # --
   ##----- end




   @@words = {}

   def self.word(key)
      return @@words[key] || key
   end

   @@words['str']  = 'string'
   @@words['int']  = 'integer'
   @@words['bool'] = 'boolean'
   @@words['seq']  = 'sequence'
   @@words['map']  = 'mapping'

end
