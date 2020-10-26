###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2006 kuwata-lab.com all rights reserved.
###


module Kwalify

  RELEASE = ("$Release: 0.7.2 $" =~ /[.\d]+/) && $&

end

require 'kwalify/types'
require 'kwalify/messages'
require 'kwalify/errors'
require 'kwalify/rule'
require 'kwalify/validator'
require 'kwalify/meta-validator'
require 'kwalify/yaml-parser'
#require 'kwalify/parser/base'
#require 'kwalify/parser/yaml'


module Kwalify

  module Util

    autoload :HashLike, 'kwalify/util/hashlike'

  end

  module Yaml

    autoload :Parser, 'kwalify/parser/yaml'

    ## read yaml_str, parse it, and return yaml document.
    ##
    ## opts:
    ## ::validator:        Kwalify::Validator object
    ## ::preceding_aliass: allow preceding alias if true
    ## ::data_binding:     enable data binding if true
    ## ::untabify:         expand tab chars if true
    ## ::filename:         filename
    def self.load(yaml_str, opts={})
      #require 'kwalify/parser/yaml'
      parser = Kwalify::Yaml::Parser.new(opts[:validator])
      parser.preceding_alias = true if opts[:preceding_alias]
      parser.data_binding    = true if opts[:data_binding]
      yaml_str = Kwalify::Util.untabify(yaml_str) if opts[:untabify]
      ydoc = parser.parse(yaml_str, :filename=>opts[:filename])
      return ydoc
    end

    ## read file, parse it, and return yaml document.
    ## see Kwalify::Yaml::Parser.load()
    def self.load_file(filename, opts={})
      opts[:filename] = filename
      return self.load(File.read(filename), opts)
    end

  end

  module Json
  end

end
