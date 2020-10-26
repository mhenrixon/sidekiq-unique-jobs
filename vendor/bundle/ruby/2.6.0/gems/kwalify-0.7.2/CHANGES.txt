.=title:          ChangeLog
.?release:        $Release: 0.7.2 $
.?lastupdate:     $Date$
.?version:        $Rev$


.: Release 0.7.2 (2010-07-18)

   .* bugfix:

      .- Fix a bug that kwalify command raised error when YAML document is empty (thanks to Nuttall).

      .- Fix a bug that Kwalify::Util.untabify() removed tailing empty strings.
         

.: Release 0.7.1 (2008-01-28)

   .* bugfix:

      .- 'Duplicated key' error is now not raised if corresponding rule
         has 'default:' constraint.

      .- Path is now copied in Kwalify::ValidationError#initialize()


.: Release 0.7.0 (2008-01-27)

   .* enhancements:

      .- YAML parser is rewrited from scratch.
         The new parser class Kwalify::Yaml::Parser is available.
	 The old parser class Kwalify::YamlParser is stil available,
	 but it is not recommended to use.

      .- Validator is integrated with yaml parser.
         It is able to parse and validate at once.
	   .--------------------
	   ## create validator
	   require 'kwalify'
	   schema = Kwalify::Yaml.load_file('schema.yaml')
	   validator = Kwalify::Validator.new(schema)
	   ## parse with validation
	   parser = Kwalify::Yaml::Parser.new(validator)
	   ydoc = parser.parse(File.read('data.yaml'))
	   ## show validation errors if exist
	   errors = parser.errors()
	   if errors && !errors.empty?
	     for e in errors
	       puts "** %d:%d [%s] %s" % [e.linenum, e.column, e.path, e.message] 
	     end
	   end
	   .--------------------

      .- Data binding is integrated into Kwalify::Yaml::Parser.
         If you set Kwalify::Yaml::Parser#data_binding to true
	 and you specified class names in schema file,
	 parser creates instance objects instead of Hash objects.
	 It means that you don't need to add '!ruby/Classname'
	 for each data.
	   .? schema file (config.schema.yaml)
	   .--------------------
	   type:  map
	   class: Config
	   mapping:
	    "host": { type: str, required: true }
	    "port": { type: int }
	    "user": { type: str, required: true }
	    "pass": { type: str, required: true }
	   .--------------------
	   .? configuration file (config.yaml)
	   .--------------------
	   host:  localhost
	   port:  8080
	   user:  user1
	   pass:  password1
	   .--------------------
	   .? ruby program (ex1.rb)
	   .--------------------
	   ## class definition
	   require 'kwalify/util/hashlike'
	   class Config
	     include Kwalify::Util::HashLike  # defines [], []=, ...
	     attr_accessor :host, :posrt, :user, :pass
	   end
	   ## create validator object
	   require 'kwalify'
	   schema = Kwalify::Yaml.load_file('config.schema.yaml')
	   validator = Kwalify::Validator.new(schema)
	   ## parse configuration file with data binding
	   parser = Kwalify::Yaml::Parser.new(validator)
	   parser.data_binding = true    # enable data binding
	   config = parser.parse_file('config.yaml')
	   p config  #=> #<Config:0x542590 @user="user1", @port=8080,
	             #        @pass="password1", @host="localhost">
	   .--------------------

      .- Preceding alias supported.
         If you set Kwalify::Yaml::Parser#preceding_alias to true,
	 parser allows aliases to apprear before corresponding anchor
	 appears.
	 This is very useful when node graph is complex.
	   .--------------------
	   - name: Foo
	     parent: *bar          # preceding alias
	   - &bar
	     name: Bar
	     parent: *baz          # preceding alias
	   - &baz
	     name: Baz
	   .--------------------

      .- New command-line option '-P' enables preceding alias.

      .- Kwalify::Yaml.load() and Kwalify::Yaml.load_file() are added.
         They are similar to YAML.load() and YAML.load_file() but they
	 use Kwalify::Yaml::Parser object.

      .- New utilify method Kwalify::Util.traverse_schema() provided.
           .--------------------
	   require 'kwalify'
	   require 'kwalify/util'
           schema = Kwalify::Yaml.load('schema.yaml')
	   Kwalify::Util.traverse_schema(schema) do |rulehash|
	     if classname = rulehash['class']
	       ## add namespace to class name
	       rulehash['class'] = "Foo::Bar::#{classname}"
	     end
	   end
           .--------------------

      .- Add 'kwalify/util/hashlike.rb' which contains definition of
         Kwalify::Util::HashLike module.
	 This module defines [], []=, keys(), key?(), and each() methods,
	 and these are required for data-binding.

      .- Action 'genclass-ruby' supports '--hashlike' property.

      .- Action 'genclass-ruby' supports '--initialize=false' property.

      .- Add action 'geclass-php'

      .- '\xXX' and '\uXXXX' are supported in Kwalify::Yaml::Parser.

      .- New constrant 'default:' is added to kwalify.schema.yaml.
         This constrant have no effect to validation and parsing,
	 and it is used only in 'genclass-xxx' action.


   .* changes:

      .- Action 'genclass-ruby' and 'genclass-java' are changed to
         generate boolean accessors.
	 For example, attribute 'active' is specified as 'type: bool'
	 in schema file, action 'genclass-ruby' generates
	   "def active? ; @active; end"
	 and action 'genclass-java' generates
	   "public boolean isActive() { return _active; }".

      .- Command-line option '-s' (silent) is obsolete and replaced with
         '-q' (quiet). Option '-s' is still available but it is recommended
	 to use '-q'.

      .- License is changed from LGPL to MIT-LICENSE.


.: Release 0.6.0 (2006-05-30)

   .* enhancements:

      .- Class definition generation support.
         New command-line option '-a genclass-ruby' or '-a genclass-java' generates
         class definitions in Ruby or Java from schema file.


.: Release 0.5.1 (2005-12-20)

   .* enhances:

      .- add new command-line option '-E' which show errors in emacs-compatible style.


.: Release 0.5.0 (2005-12-17)

   .* enhancements:

      .- Meta-validation check for 'max < min', 'max-ex <= min-ex', and so on.
      .- Many test-cases are added

   .* changes:

      .- 'Parser' class is renamed to 'YamlParser'
      .- 'PlainParser' class is renamed to 'PlainYamlParser'
      .- YamlParser#set_error_linenums() is renamed to set_errors_linenum()
      .- ValidatorError#<=> added
      .- ParseError class is renamed to YamlSyntaxError


.: Release 0.4.1 (2005-10-26)

   .* bugfix:

      .- Support Ruby 1.8.3 (around YAML::Syck::DomainType)
      .- Show correct error line number when key is undefined or unknown.


.: Release 0.4.0 (2005-10-25)

   .* enhancements:

      .- New command-line option '-l' prints error line numbers.
      .- Supports default rule of mapping.


.: Release 0.3.0 (2005-09-30)

   .* enhancements:

      .- Support 'max-ex' and 'min-ex' (max/min exclusive) support with 'range:'
      .- Support 'max-ex' and 'min-ex' (max/min exclusive) support with 'length:'
      .- Support 'unique' constraint


.: Release 0.2.0 (2005-09-25)

   .* enhancements:

      .- New type 'scalar' and 'timestamp' added
      .- Add new rule 'range:' which validates value range.
         See users' guide for details.
      .- Add new rule 'length:' which validate length of string value.
         See users' guide for details.
      .- Add experimental rule 'assert:' which validates value with an
         expression. See users' guide for details.
      .- New method 'Kwalify::Validator#validate_hook()' is added.
         This method is called by Kwalify::Validator#validate().
         See users' guide for details.
      .- New class 'MetaValidator' added.
      .- New test script 'test/test-metavalidator.rb' added.

   .* changes:

      .- Type name changed to suite YAML data type:
         .= string -> str
         .= integer -> int
         .= boolean -> bool
      .- Error index starts with 0 (before starts with 1).
      .- Class 'Schema' is renamed to 'Rule'.


.: Release 0.1.0 (2005-08-01)

    .- beta release
