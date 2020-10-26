###
### $Rev$
### $Release: 0.7.2 $
### copyright(c) 2005-2010 kuwata-lab all rights reserved.
###

require 'date'


module Kwalify
  module Boolean  # :nodoc:
  end
end
class TrueClass   # :nodoc:
  include Kwalify::Boolean
end
class FalseClass  # :nodoc:
  include Kwalify::Boolean
end
#module Boolean; end
#class TrueClass
#  include Boolean
#end
#class FalseClass
#  include Boolean
#end


module Kwalify
  module Text  # :nodoc:
  end
end
class String   # :nodoc:
  include Kwalify::Text
end
class Numeric  # :nodoc:
  include Kwalify::Text
end
#module Text; end
#class String
#  include Text
#end
#class Numeric
#  include Text
#end


module Kwalify
  module Scalar  # :nodoc:
  end
end
class String     # :nodoc:
  include Kwalify::Scalar
end
class Numeric    # :nodoc:
  include Kwalify::Scalar
end
class Date       # :nodoc:
  include Kwalify::Scalar
end
class Time       # :nodoc:
  include Kwalify::Scalar
end
class TrueClass  # :nodoc:
  include Kwalify::Scalar
end
class FalseClass # :nodoc:
  include Kwalify::Scalar
end
class NilClass   # :nodoc:
  include Kwalify::Scalar
end
module Kwalify
  module Text    # :nodoc:
    include Kwalify::Scalar
  end
end


module Kwalify


  module Types


    DEFAULT_TYPE = "str"        ## use "str" as default of @type

    @@type_table = {
      "seq"     => Array,
      "map"     => Hash,
      "str"     => String,
      #"string"   => String,
      "text"    => Text,
      "int"     => Integer,
      #"integer"  => Integer,
      "float"    => Float,
      "number"   => Numeric,
      #"numeric"  => Numeric,
      "date"    => Date,
      "time"    => Time,
      "timestamp" => Time,
      "bool"    => Boolean,
      #"boolean"  => Boolean,
      #"object"   => Object,
      "any"     => Object,
      "scalar"   => Scalar,
    }

    def self.type_table
      return @@type_table
    end

    def self.type_class(type)
      klass = @@type_table[type]
      #assert_error('type=#{type.inspect}') unless klass
      return klass
    end

    def self.get_type_class(type)
      return type_class(type)
    end



    #--
    #def collection_class?(klass)
    #  return klass.is_a?(Array) || klass.is_a?(Hash)
    #end
    #
    #def scalar_class?(klass)
    #  return !klass.is_a?(Array) && !klass.is_a?(Hash) && klass != Object
    #end

    def collection?(val)
      return val.is_a?(Array) || val.is_a?(Hash)
    end

    def scalar?(val)
      #return !val.is_a?(Array) && !val.is_a?(Hash) && val.class != Object
      return val.is_a?(Kwalify::Scalar)  #&& val.class != Object
    end

    def collection_type?(type)
      return type == 'seq' || type == 'map'
    end

    def scalar_type?(type)
      return type != 'seq' && type != 'map' && type == 'any'
    end

    module_function 'collection?', 'scalar?', 'collection_type?', 'scalar_type?'
  end

  extend Types

end
