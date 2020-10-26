###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'yaml'
require 'erb'
require 'kwalify'
require 'kwalify/util'
require 'kwalify/util/ordered-hash'


module Kwalify


  class CommandOptionError < KwalifyError
    def initialize(message, option, error_symbol)
      super(message)
      @option = option
      @error_symbol = error_symbol
    end
    attr_reader :option, :error_symbol
  end


  ##
  ## ex.
  ##  command = File.basename($0)
  ##  begin
  ##    main = Kwalify::Main.new(command)
  ##    s = main.execute
  ##    print s if s
  ##  rescue Kwalify::CommandOptionError => ex
  ##    $stderr.puts "ERROR: #{ex.message}"
  ##    exit 1
  ##  rescue Kwalify::KwalifyError => ex
  ##    $stderr.puts "ERROR: #{ex.message}"
  ##    exit 1
  ##  end
  ##
  class Main


    def initialize(command=nil)
      @command = command || File.basename($0)
      @options = {}
      @properties   = {}
      @template_path  = []
      $:.each do |path|
        tpath = "#{path}/kwalify/templates"
        @template_path << tpath if test(?d, tpath)
      end
    end


    def debug?
      @options[:debug]
    end


    def _inspect()
      sb = []
      sb <<   "command: #{@command}\n"
      sb <<   "options:\n"
      @options.keys.sort {|k1,k2| k1.to_s<=>k2.to_s }.each do |key|
        sb << "  - #{key}: #{@options[key]}\n"
      end
      sb <<   "properties:\n"
      @properties.keys.sort_by {|k| k.to_s}.each do |key|
        sb << "  - #{key}: #{@properties[key]}\n"
      end
      #sb <<   "template_path:\n"
      #@template_path.each do |path|
      #  sb << "  - #{path}\n"
      #end
      return sb.join
    end


    def execute(argv=ARGV)
      ## parse command-line options
      filenames = _parse_argv(argv)

      ## help or version
      if @options[:help] || @options[:version]
        action = @options[:action]
        s = ''
        s << _version() << "\n"           if @options[:version]
        s << _usage()                     if @options[:help] && !action
        s << _describe_properties(action) if @options[:help] && action
        puts s
        return
      end

      # validation
      if @options[:meta2]
        validate_schemafiles2(filenames)
      elsif @options[:meta]
        validate_schemafiles(filenames)
      elsif @options[:action]
        unless @options[:schema]
          #* key=:command_option_actionnoschema  msg="schema filename is not specified."
          raise option_error(:command_option_actionnoschema, @options[:action])
        end
        perform_action(@options[:action], @options[:schema])
      elsif @options[:schema]
        if @options[:debug]
          inspect_schema(@options[:schema])
        else
          validate_files(filenames, @options[:schema])
        end
      else
        #* key=:command_option_noaction  msg="command-line option '-f' or '-m' required."
        raise option_error(:command_option_noaction, @command)
      end
      return
    end


    def self.main(command, argv=ARGV)
      begin
        main = Kwalify::Main.new(command)
        s = main.execute(argv)
        print s if s
      rescue Kwalify::CommandOptionError => ex
        raise ex if main.debug?
        $stderr.puts ex.message
        exit 1
      rescue Kwalify::KwalifyError => ex
        raise ex if main.debug?
        $stderr.puts "ERROR: #{ex.to_s}"
        exit 1
      #rescue => ex
      #  if main.debug?
      #    raise ex
      #  else
      #    $stderr.puts ex.message
      #    exit 1
      #  end
      end
    end


    private


    def option_error(error_symbol, arg)
      msg = Kwalify.msg(error_symbol) % arg
      return CommandOptionError.new(msg, arg, error_symbol)
    end


    def _find_template(action)
      template_filename = action + '.eruby'
      unless test(?f, template_filename)
        pathlist = []
        pathlist.concat(@options[:tpath].split(/,/)) if @options[:tpath]
        pathlist.concat(@template_path)
        tpath = pathlist.find {|path| test(?f, "#{path}/#{template_filename}") }
        #* key=:command_option_notemplate  msg="%s: invalid action (template not found).\n"
        raise option_error(:command_option_notemplate, action) unless tpath
        template_filename = "#{tpath}/#{action}.eruby"
      end
      return template_filename
    end


    def apply_template(template_filename, hash)
      template = File.read(template_filename)
      trim_mode = 1
      erb = ERB.new(template, nil, trim_mode)
      context = Object.new
      hash.each do |key, val|
        context.instance_variable_set("@#{key}", val)
      end
      s = context.instance_eval(erb.src, template_filename)
      return s
    end


    def _describe_properties(action)
      template_filename = _find_template(action)
      s = apply_template(template_filename, :describe=>true)
      return s
    end


    def perform_action(action, schema_filename, describe=false)
      template_filename = _find_template(action)
      schema = _load_schemafile(schema_filename, ordered=true)
      validator = Kwalify::Validator.new(schema)
      @properties[:schema_filename] = schema_filename
      hash = { :validator=>validator, :schema=>schema, :properties=>@properties }
      s = apply_template(template_filename, hash)
      puts s if s && !s.empty?
    end


    def inspect_schema(schema_filename)
      schema = _load_schemafile(schema_filename)
      if schema.nil?
        puts "nil"
      else
        validator = Kwalify::Validator.new(schema)  # error raised when schema is wrong
        puts validator._inspect()
      end
    end


    ## -f schemafile datafile
    def validate_files(filenames, schema_filename)
      schema = _load_schemafile(schema_filename)
      validator = Kwalify::Validator.new(schema)
      _validate_files(validator, filenames)
    end


    def _load_schemafile(schema_filename, ordered=false)
      str = File.read(schema_filename)
      if str.empty?
        #* key=:schema_empty  msg="%s: empty schema.\n"
        msg = Kwalify.msg(:schema_emtpy) % filename
        raise CommandOptionError.new(msg)
      end
      str = Util.untabify(str) if @options[:untabify]
      parser = Kwalify::Yaml::Parser.new()
      parser.preceding_alias = true if @options[:preceding]
      parser.mapping_class = Kwalify::Util::OrderedHash if ordered
      schema = parser.parse(str, :filename=>schema_filename) # or YAML.load(str)
      return schema
    end


    ## -m schemafile
    def validate_schemafiles(schema_filenames)
      meta_validator = Kwalify::MetaValidator.instance()
      _validate_files(meta_validator, schema_filenames)
    end


    ## -M schemafile
    def validate_schemafiles2(schema_filenames)
      parser = Kwalify::Yaml::Parser.new()
      parser.preceding_alias = true if @options[:preceding]
      for schema_filename in schema_filenames
        str = File.read(schema_filename)
        str = Util.untabify(str) if @options[:untabify]
        schema = parser.parse(str, :filename=>schema_filename)
        Kwalify::Validator.new(schema)   # exception raised when schema has errors
      end
    end


    def _validate_files(validator, filenames)
      ## parser
      if @options[:linenum] || @options[:preceding]
        parser = Kwalify::Yaml::Parser.new(validator)
        parser.preceding_alias = true if @options[:preceding]
      else
        parser = nil
      end
      ## filenames
      if filenames.empty?
        filenames = [ $stdin ]
      end
      for filename in filenames
        ## read input
        if filename.is_a?(IO)
          input = filename.read()
          filename = '(stdin)'
        else
          input = File.read(filename)
        end
        if input.empty?
          #* key=:validation_empty  msg="%s#%d: empty."
          puts kwalify.msg(:validation_empty) % [filename, i]
          #puts "#{filename}##{i}: empty."
          next
        end
        input = Util.untabify(input) if @options[:untabify]
        ## parse input
        if parser
          #i = 0
          #ydoc = parser.parse(input, :filename=>filename)
          #_show_errors(filename, i, ydoc, parser.errors)
          #while parser.has_next?
          #  i += 1
          #  ydoc = parser.parse_next()
          #  _show_errors(filename, i, ydoc, parser.errors)
          #end
          i = 0
          parser.parse_stream(input, :filename=>filename) do |ydoc|
            _show_errors(filename, i, ydoc, parser.errors)
            i += 1
          end
        else
          i = 0
          YAML.load_documents(input) do |ydoc|
            errors = validator.validate(ydoc)
            _show_errors(filename, i, ydoc, errors)
            i += 1
          end
        end
      end
    end


    def _show_errors(filename, i, ydoc, errors, ok_label="valid.", ng_label="INVALID")
      if errors && !errors.empty?
        puts "#{filename}##{i}: #{ng_label}"
        errors.sort!
        for error in errors
          e = error
          if @options[:emacs]
            raise unless @options[:linenum]
            puts "#{filename}:#{e.linenum}:#{e.column} [#{e.path}] #{e.message}\n"
          elsif @options[:linenum]
            puts "  - (line #{e.linenum}) [#{e.path}] #{e.message}\n"
          else
            puts "  - [#{e.path}] #{e.message}\n"
          end
        end
      elsif ydoc.nil?
        #* key=:validation_empty  msg="%s#%d: empty.\n"
        puts Kwalify.msg(:validation_empty) % [filename, i]
      else
        #* key=:validation_valid  msg="%s#%d: valid."
        puts Kwalify.msg(:validation_valid) % [filename, i] unless @options[:quiet]
        #puts "#{filename}##{i} - #{ok_label}" unless @options[:quiet]
      end
    end


    def _usage()
      #msg = Kwalify.msg(:command_help) % [@command, @command, @command]
      msg = Kwalify.msg(:command_help)
      return msg
    end


    def _version()
      return RELEASE
    end


    def _to_value(str)
      case str
      when nil, "null", "nil"     ;  return nil
      when "true", "yes"          ;  return true
      when "false", "no"          ;  return false
      when /\A\d+\z/              ;  return str.to_i
      when /\A\d+\.\d+\z/         ;  return str.to_f
      when /\/(.*)\//             ;  return Regexp.new($1)
      when /\A'.*'\z/, /\A".*"\z/ ;  return eval(str)
      else                        ;  return str
      end
    end


    def _parse_argv(argv)
      option_table = {
        ?h => :help,
        ?v => :version,
        ?q => :quiet,
        ?s => :quiet,
        ?t => :untabify,
        #?z => :meta,
        ?m => :meta,
        ?M => :meta2,
        ?E => :emacs,
        ?l => :linenum,
        ?f => :schema,
        ?D => :debug,
        ?a => :action,
        ?I => :tpath,
        ?P => :preceding,
      }

      errcode_table = {
        #* key=:command_option_schema_required  msg="-%s: schema filename required."
        ?f => :command_option_schema_required,
        #* key=:command_option_action_required  msg="-%s: action required."
        ?a => :command_option_action_required,
        #* key=:command_option_tpath_required  msg="-%s: template path required."
        ?I => :command_option_tpath_required,
      }

      while argv[0] && argv[0][0] == ?-
        optstr = argv.shift
        optstr = optstr[1, optstr.length-1]
        ## property
        if optstr[0] == ?-
          unless optstr =~ /\A\-([-\w]+)(?:=(.*))?\z/
            #* key=:command_property_invalid  msg="%s: invalid property."
            raise option_error(:command_property_invalid, optstr)
          end
          prop_name = $1;  prop_value = $2
          key  = prop_name.gsub(/-/, '_').intern
          value = prop_value.nil? ? true : _to_value(prop_value)
          @properties[key] = value
        ## option
        else
          while optstr && !optstr.empty?
            optchar = optstr[0]
            optstr[0,1] = ""
            unless option_table.key?(optchar)
              #* key=:command_option_invalid  msg="-%s: invalid command option."
              raise option_error(:command_option_invalid, optchar.chr)
            end
            optkey = option_table[optchar]
            case optchar
            when ?f, ?a, ?I
              arg = optstr.empty? ? argv.shift : optstr
              raise option_error(errcode_table[optchar], optchar.chr) unless arg
              @options[optkey] = arg
              optstr = ''
            else
              @options[optkey] = true
            end
          end
        end
      end  # end of while
      #
      @options[:linenum] = true if @options[:emacs]
      @options[:help]    = true if @properties[:help]
      @options[:version] = true if @properties[:version]
      filenames = argv
      return filenames
    end


    def _domain_type?(doc)
      klass = defined?(YAML::DomainType) ? YAML::DomainType : YAML::Syck::DomainType
      return doc.is_a?(klass)
    end


  end


end
