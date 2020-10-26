require 'yaml'
ydoc = YAML.load_file('tapkit.yaml')

require 'tapkit'
schema = Tapkit::Schema.new(ydoc)
require 'pp'
pp schema
