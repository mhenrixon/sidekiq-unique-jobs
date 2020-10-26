require 'kwalify'
#require 'yaml'

## load schema data
schema = Kwalify::Yaml.load_file('schema.yaml')
## or
#schema = YAML.load_file('schema.yaml')

## create validator
validator = Kwalify::Validator.new(schema)

## create parser with validator
## (if validator is ommitted, no validation executed.)
parser = Kwalify:::Yaml::Parser.new(validator)

## parse document with validation
filename = 'document.yaml'
document = parser.parse_file(filename)
## or
#document = parser.parse(File.read(filename), filename)

## show errors if exist
errors = parser.errors()
if errors && !errors.empty?
  for e in errors
    puts "#{e.linenum}:#{e.column} [#{e.path}] #{e.message}"
  end
end
