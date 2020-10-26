require 'kwalify'
require 'models'

## load schema definition
schema = Kwalify::Yaml.load_file('BABEL.schema.yaml',
                                 :untabify=>true,
                                 :preceding_alias=>true)

## add module name to 'class:'
Kwalify::Util.traverse_schema(schema) do |rulehash|
  if rulehash['class']
    rulehash['class'] = 'Babel::' + rulehash['class']
  end
end

## create validator
validator = Kwalify::Validator.new(schema)

## parse with data-binding
parser = Kwalify::Yaml::Parser.new(validator)
parser.preceding_alias = true
parser.data_binding = true
ydoc = parser.parse_file('BABEL.data.yaml', :untabify=>true)

## show document
require 'pp'
pp ydoc
