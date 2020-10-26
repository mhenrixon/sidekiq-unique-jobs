require 'kwalify'
#require 'yaml'

## load schema data
schema = Kwalify::Yaml.load_file('schema.yaml')
## or
#schema = YAML.load_file('schema.yaml')

## create validator
validator = Kwalify::Validator.new(schema)

## load document
document = Kwalify::Yaml.load_file('document.yaml')
## or
#document = YAML.load_file('document.yaml')

## validate
errors = validator.validate(document)

## show errors
if errors && !errors.empty?
  for e in errors
    puts "[#{e.path}] #{e.message}"
  end
end
