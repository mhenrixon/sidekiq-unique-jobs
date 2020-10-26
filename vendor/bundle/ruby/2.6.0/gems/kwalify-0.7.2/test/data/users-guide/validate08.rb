#!/usr/bin/env ruby

require 'kwalify'
require 'yaml'

## load schema definition
schema = YAML.load_file('answers-schema.yaml')

## create validator for answers
validator = Kwalify::Validator.new(schema) { |value, rule, path, errors|
   case rule.name
   when 'Answer'
      if value['answer'] == 'bad'
         reason = value['reason']
         if !reason || reason.empty?
            msg = "reason is required when answer is 'bad'."
            errors << Kwalify::ValidationError.new(msg, path)
         end
      end
   end
}

## load YAML document
input = ARGF.read()
document = YAML.load(input)

## validate
errors = validator.validate(document)
if errors.empty?
   puts "Valid."
else
   puts "*** INVALID!"
   errors.each do |error|
      # error.class == Kwalify::ValidationError
      puts " - [#{error.path}] : #{error.message}"
   end
end
