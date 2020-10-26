#!/usr/bin/env ruby

require 'kwalify'

## validator class for answers
class AnswersValidator < Kwalify::Validator

   ## load schema definition
   @@schema = Kwalify::Yaml.load_file('answers-schema.yaml')
   ## or
   ##   require 'yaml'
   ##   @@schema = YAML.load_file('answers-schema.yaml')

   def initialize()
      super(@@schema)
   end

   ## hook method called by Validator#validate()
   def validate_hook(value, rule, path, errors)
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
   end

end

## create validator
validator = AnswersValidator.new

## parse and validate YAML document
input = ARGF.read()
parser = Kwalify::Yaml::Parser.new(validator)
document = parser.parse(input)

## show errors
errors = parser.errors()
if !errors || errors.empty?
   puts "Valid."
else
   puts "*** INVALID!"
   for e in errors
      # e.class == Kwalify::ValidationError
      puts "#{e.linenum}:#{e.column} [#{e.path}] #{e.message}"
   end
end
