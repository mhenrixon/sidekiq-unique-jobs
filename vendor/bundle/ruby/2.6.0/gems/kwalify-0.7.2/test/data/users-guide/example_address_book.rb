require 'address_book'
require 'yaml'
require 'pp'

str = File.read('address_book.yaml')
ydoc = YAML.load(str)
addrbook = AddressBook.new(ydoc)

pp addrbook.groups
pp addrbook.people
