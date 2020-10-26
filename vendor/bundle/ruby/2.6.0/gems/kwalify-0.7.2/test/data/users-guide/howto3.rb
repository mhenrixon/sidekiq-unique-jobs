require 'kwalify'
parser = Kwalify::Yaml::Parser.new
parser.preceding_alias = true   # enable preceding alias
ydoc = parser.parse_file('howto3.yaml')
require 'pp'
pp ydoc
